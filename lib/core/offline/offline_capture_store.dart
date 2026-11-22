import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

typedef Capture = Map<String, dynamic>;

/// No clinical content is stored in plaintext, including SQLite journals.
/// Metadata and photo bytes use AES-GCM with account/id as associated data.
class OfflineCaptureStore {
  OfflineCaptureStore(this.db, this.keyForAccount);
  final Database db;
  final Future<SecretKey> Function(String) keyForAccount;
  final _cipher = AesGcm.with256bits();

  static final Future<OfflineCaptureStore> _deviceStore = _open();

  static Future<OfflineCaptureStore> open() => _deviceStore;

  static Future<OfflineCaptureStore> _open() async {
    final directory = await const MethodChannel(
      'triage/offline_storage',
    ).invokeMethod<String>('protectedDirectory');
    if (directory == null) {
      throw StateError('Almacenamiento protegido no disponible.');
    }
    final db = await openDatabase(
      p.join(directory, 'captures.db'),
      version: 1,
      onCreate: createSchema,
      onConfigure: (db) async {
        await db.execute('PRAGMA synchronous = FULL');
        await db.execute('PRAGMA secure_delete = ON');
      },
    );
    const secure = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    );
    final keys = <String, Future<SecretKey>>{};
    return OfflineCaptureStore(
      db,
      (account) => keys.putIfAbsent(account, () async {
        try {
          final name = 'triage_captures_v1_$account';
          final existing = await secure.read(key: name);
          if (existing != null) return SecretKey(base64Decode(existing));
          final rows = await db.rawQuery(
            'SELECT id FROM captures WHERE account = ? '
            'UNION ALL SELECT id FROM incident_cache WHERE account = ? LIMIT 1',
            [account, account],
          );
          if (rows.isNotEmpty) {
            throw StateError('La clave local no está disponible.');
          }
          final key = await AesGcm.with256bits().newSecretKey();
          await secure.write(
            key: name,
            value: base64Encode(await key.extractBytes()),
          );
          return key;
        } catch (_) {
          keys.remove(account);
          rethrow;
        }
      }),
    );
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute(
      'CREATE TABLE captures (account TEXT NOT NULL, id TEXT NOT NULL, body BLOB NOT NULL, PRIMARY KEY(account,id))',
    );
    await db.execute(
      'CREATE TABLE outbox (account TEXT NOT NULL, id TEXT NOT NULL, PRIMARY KEY(account,id))',
    );
    await db.execute(
      'CREATE TABLE attachments (account TEXT NOT NULL, capture_id TEXT NOT NULL, id TEXT NOT NULL, body BLOB NOT NULL, PRIMARY KEY(account,id))',
    );
    await db.execute(
      'CREATE TABLE incident_cache (account TEXT NOT NULL, id TEXT NOT NULL, body BLOB NOT NULL, PRIMARY KEY(account,id))',
    );
  }

  Future<Uint8List> _seal(String account, String id, List<int> bytes) async {
    final box = await _cipher.encrypt(
      bytes,
      secretKey: await keyForAccount(account),
      aad: utf8.encode('$account/$id'),
    );
    return Uint8List.fromList(box.concatenation());
  }

  Future<List<int>> _unseal(String account, String id, Object bytes) async =>
      _cipher.decrypt(
        SecretBox.fromConcatenation(
          bytes as Uint8List,
          nonceLength: 12,
          macLength: 16,
        ),
        secretKey: await keyForAccount(account),
        aad: utf8.encode('$account/$id'),
      );

  static Capture draft({
    required String id,
    required String kind,
    required Capture payload,
    String? parentId,
  }) {
    final capturedAt = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'kind': kind,
      'payload': {...payload, 'captured_at': capturedAt},
      'parent_id': parentId,
      'captured_at': capturedAt,
      'state': 'pending',
      'attempts': 0,
      'photos': <Capture>[],
    };
  }

  /// A quick-registration incident and patient can share this transaction.
  /// Files are read and encrypted first; any failure leaves no accepted capture.
  Future<void> enqueue(
    String account,
    List<Capture> captures,
    Map<String, List<String>> files, {
    required bool Function() authorized,
  }) async {
    final bodies = <String, Uint8List>{};
    final blobs = <String, Map<String, Uint8List>>{};
    for (final capture in captures) {
      final id = capture['id'] as String;
      final photos = <Capture>[];
      blobs[id] = {};
      final paths = files[id] ?? [];
      for (var i = 0; i < paths.length; i++) {
        final ext = p.extension(paths[i]).replaceFirst('.', '').toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
          throw const FormatException(
            'Foto no admitida. Usa JPEG, PNG, WebP o HEIC.',
          );
        }
        try {
          final file = File(paths[i]);
          if (await file.length() > 10485760) {
            throw const FormatException(
              'Cada foto debe ocupar como máximo 10 MB.',
            );
          }
          final photoId = const Uuid().v4();
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty || bytes.length > 10485760) {
            throw const FormatException('Foto vacía o mayor de 10 MB.');
          }
          blobs[id]![photoId] = await _seal(account, photoId, bytes);
          photos.add({
            'id': photoId,
            'extension': ext,
            'mime': 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            'uploaded': false,
            'linked': false,
          });
        } on FileSystemException {
          throw FileSystemException(
            'No se pudo conservar la foto ${i + 1}. Vuelve a seleccionarla.',
          );
        }
      }
      capture['photos'] = photos;
      bodies[id] = await _seal(account, id, utf8.encode(jsonEncode(capture)));
    }
    await db.transaction((tx) async {
      if (!authorized()) {
        throw StateError('La sesión cambió. Vuelve a autenticarte.');
      }
      for (final entry in bodies.entries) {
        await tx.insert('captures', {
          'account': account,
          'id': entry.key,
          'body': entry.value,
        });
        await tx.insert('outbox', {'account': account, 'id': entry.key});
        for (final file in blobs[entry.key]!.entries) {
          await tx.insert('attachments', {
            'account': account,
            'capture_id': entry.key,
            'id': file.key,
            'body': file.value,
          });
        }
      }
      if (!authorized()) {
        throw StateError('La sesión cambió. Vuelve a autenticarte.');
      }
    });
  }

  Future<List<Capture>> list(String account) async {
    final rows = await db.query(
      'captures',
      where: 'account = ?',
      whereArgs: [account],
    );
    return Future.wait(
      rows.map(
        (row) async => Capture.from(
          jsonDecode(
                utf8.decode(
                  await _unseal(account, row['id']! as String, row['body']!),
                ),
              )
              as Map,
        ),
      ),
    );
  }

  Future<bool> hasPending(String account) async => (await db.query(
    'outbox',
    columns: ['id'],
    where: 'account = ?',
    whereArgs: [account],
    limit: 1,
  )).isNotEmpty;

  Future<Capture?> get(String account, String id) async {
    final rows = await db.query(
      'captures',
      where: 'account = ? AND id = ?',
      whereArgs: [account, id],
    );
    if (rows.isEmpty) return null;
    return Capture.from(
      jsonDecode(utf8.decode(await _unseal(account, id, rows.single['body']!)))
          as Map,
    );
  }

  Future<void> save(String account, Capture capture) async {
    final id = capture['id'] as String;
    final body = await _seal(account, id, utf8.encode(jsonEncode(capture)));
    await db.transaction((tx) async {
      if (await tx.update(
            'captures',
            {'body': body},
            where: 'account = ? AND id = ?',
            whereArgs: [account, id],
          ) !=
          1) {
        throw StateError('Captura local no encontrada.');
      }
      if (capture['state'] == 'synced') {
        await tx.delete(
          'outbox',
          where: 'account = ? AND id = ?',
          whereArgs: [account, id],
        );
        await tx.delete(
          'attachments',
          where: 'account = ? AND capture_id = ?',
          whereArgs: [account, id],
        );
      }
    });
  }

  Future<Uint8List> attachment(String account, String id) async {
    final rows = await db.query(
      'attachments',
      where: 'account = ? AND id = ?',
      whereArgs: [account, id],
    );
    if (rows.isEmpty) {
      throw StateError('Falta una foto guardada. Requiere atención.');
    }
    return Uint8List.fromList(await _unseal(account, id, rows.single['body']!));
  }

  Future<void> cacheIncident(String account, Capture row) async {
    final id = row['id'] as String;
    await db.insert('incident_cache', {
      'account': account,
      'id': id,
      'body': await _seal(account, 'cache/$id', utf8.encode(jsonEncode(row))),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Capture?> cachedIncident(String account, String id) async {
    final rows = await db.query(
      'incident_cache',
      where: 'account = ? AND id = ?',
      whereArgs: [account, id],
    );
    if (rows.isEmpty) return null;
    return Capture.from(
      jsonDecode(
            utf8.decode(
              await _unseal(account, 'cache/$id', rows.single['body']!),
            ),
          )
          as Map,
    );
  }
}
