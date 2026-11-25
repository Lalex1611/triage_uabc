import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

typedef Capture = Map<String, dynamic>;
typedef CaptureReadResult = ({List<Capture> rows, List<String> unreadableIds});
const emptyCaptureReadResult = (rows: <Capture>[], unreadableIds: <String>[]);

/// Los datos clínicos se guardan cifrados, incluso en los diarios de SQLite.
/// Los metadatos y las fotos usan AES-GCM con la cuenta y el identificador
/// como datos asociados.
class OfflineCaptureStore {
  OfflineCaptureStore(this.db, this.keyForAccount, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const schemaVersion = 2;
  static const _retention = Duration(hours: 24);
  static const _unexpired = '(expires_at IS NULL OR expires_at > ?)';

  final Database db;
  final Future<SecretKey> Function(String) keyForAccount;
  final DateTime Function() _now;
  final _cipher = AesGcm.with256bits();

  static Future<OfflineCaptureStore>? _deviceStore;

  static Future<OfflineCaptureStore> open() =>
      _deviceStore ??= _open().catchError((Object error, StackTrace trace) {
        _deviceStore = null;
        Error.throwWithStackTrace(error, trace);
      });

  static Future<OfflineCaptureStore> _open() async {
    final directory = await const MethodChannel(
      'triage/offline_storage',
    ).invokeMethod<String>('protectedDirectory');
    if (directory == null) {
      throw StateError('Almacenamiento protegido no disponible.');
    }
    final db = await openDatabase(
      p.join(directory, 'captures.db'),
      version: schemaVersion,
      onCreate: createSchema,
      onConfigure: (db) async {
        await db.execute('PRAGMA synchronous = FULL');
        // SQLite devuelve el nuevo valor y Android necesita leerlo como fila.
        await db.rawQuery('PRAGMA secure_delete = ON');
      },
    );
    const secure = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    );
    final keys = <String, Future<SecretKey>>{};
    final store = OfflineCaptureStore(
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
    await store._cleanUp();
    AppLifecycleListener(onResume: () => unawaited(store._cleanUp()));
    Timer.periodic(const Duration(seconds: 15), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(store._cleanUp());
      }
    });
    return store;
  }

  static Future<void> createSchema(Database db, int _) async {
    await db.execute(
      'CREATE TABLE captures (account TEXT NOT NULL, id TEXT NOT NULL, '
      'body BLOB NOT NULL, expires_at INTEGER, PRIMARY KEY(account,id))',
    );
    await db.execute(
      'CREATE INDEX captures_expires_at ON captures(expires_at) '
      'WHERE expires_at IS NOT NULL',
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

  Future<void> _cleanUp() async {
    try {
      await purgeExpired();
    } on DatabaseException {
      debugPrint('No se pudieron limpiar las capturas vencidas.');
    }
  }

  Future<void> purgeExpired() async {
    final cutoff = _now().millisecondsSinceEpoch;
    const expired =
        'expires_at <= ? AND NOT EXISTS ('
        'SELECT 1 FROM outbox o WHERE o.account = captures.account '
        'AND o.id = captures.id)';
    await db.transaction((tx) async {
      await tx.rawDelete(
        'DELETE FROM incident_cache WHERE rowid IN ('
        'SELECT cache.rowid FROM captures '
        'JOIN incident_cache cache USING (account, id) WHERE $expired)',
        [cutoff],
      );
      await tx.delete('captures', where: expired, whereArgs: [cutoff]);
    });
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

  /// El incidente y el paciente de un registro rápido se pueden guardar en la
  /// misma transacción. Primero se leen y cifran los archivos. Si algún paso
  /// falla, la captura no se confirma.
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

  Future<CaptureReadResult> list(String account) async {
    final rows = await db.query(
      'captures',
      where: 'account = ? AND $_unexpired',
      whereArgs: [account, _now().millisecondsSinceEpoch],
    );
    final entries = await Future.wait(
      rows.map((row) async {
        final id = row['id']! as String;
        try {
          return (id, await _decodeCapture(account, id, row['body']!));
        } catch (_) {
          return (id, null);
        }
      }),
    );
    return (
      rows: [for (final (_, capture) in entries) ?capture],
      unreadableIds: [
        for (final (id, capture) in entries)
          if (capture == null) id,
      ],
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
      where: 'account = ? AND id = ? AND $_unexpired',
      whereArgs: [account, id, _now().millisecondsSinceEpoch],
    );
    if (rows.isEmpty) return null;
    return _decodeCapture(account, id, rows.single['body']!);
  }

  Future<Capture> _decodeCapture(
    String account,
    String id,
    Object body,
  ) async => Capture.from(
    jsonDecode(utf8.decode(await _unseal(account, id, body))) as Map,
  );

  Future<void> save(String account, Capture capture) async {
    final id = capture['id'] as String;
    final body = await _seal(account, id, utf8.encode(jsonEncode(capture)));
    final synced = capture['state'] == 'synced';
    await db.transaction((tx) async {
      if (await tx.rawUpdate(
            'UPDATE captures SET body = ?, '
            'expires_at = COALESCE(expires_at, ?) WHERE account = ? AND id = ?',
            [
              body,
              synced ? _now().add(_retention).millisecondsSinceEpoch : null,
              account,
              id,
            ],
          ) !=
          1) {
        throw StateError('Captura local no encontrada.');
      }
      if (synced) {
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

  Future<void> cacheIncident(
    String account,
    Capture row, {
    bool Function()? authorized,
  }) async {
    final id = row['id'] as String;
    final body = await _seal(
      account,
      'cache/$id',
      utf8.encode(jsonEncode(row)),
    );
    if (authorized?.call() == false) return;
    await db.insert('incident_cache', {
      'account': account,
      'id': id,
      'body': body,
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
