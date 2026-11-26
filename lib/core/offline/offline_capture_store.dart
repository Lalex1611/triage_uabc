import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

typedef Capture = Map<String, dynamic>;
typedef CaptureReadResult = ({List<Capture> rows, List<String> unreadableIds});
const emptyCaptureReadResult = (rows: <Capture>[], unreadableIds: <String>[]);

/// Los datos clínicos se guardan cifrados, incluso en los diarios de SQLite.
/// Los metadatos y las fotos usan AES-GCM con la cuenta y el identificador
/// como datos asociados.
class OfflineCaptureStore {
  OfflineCaptureStore(
    this.db,
    this.keyForAccount, {
    DateTime Function()? now,
    Future<Directory> Function()? pickerDirectory,
  }) : _now = now ?? DateTime.now,
       _pickerDirectory = pickerDirectory;

  static const schemaVersion = 3;
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static const _retention = Duration(hours: 24);
  static const _unexpired = '(expires_at IS NULL OR expires_at > ?)';

  final Database db;
  final Future<SecretKey> Function(String) keyForAccount;
  final DateTime Function() _now;
  final Future<Directory> Function()? _pickerDirectory;
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
      onUpgrade: upgradeSchema,
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
      pickerDirectory: Platform.isIOS
          ? () async => Directory.systemTemp
          : getTemporaryDirectory,
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
      'CREATE TABLE incident_cache (account TEXT NOT NULL, id TEXT NOT NULL, '
      'body BLOB NOT NULL, expires_at INTEGER NOT NULL, PRIMARY KEY(account,id))',
    );
    await db.execute(
      'CREATE INDEX incident_cache_expires_at ON incident_cache(expires_at)',
    );
  }

  static Future<void> upgradeSchema(Database db, int oldVersion, int _) async {
    if (oldVersion < 3) {
      // Las copias anteriores carecen de fecha y se pueden descargar otra vez.
      await db.delete('incident_cache');
      await db.execute(
        'ALTER TABLE incident_cache ADD COLUMN expires_at INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'CREATE INDEX incident_cache_expires_at ON incident_cache(expires_at)',
      );
    }
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
      await tx.delete(
        'incident_cache',
        where: 'expires_at <= ?',
        whereArgs: [cutoff],
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
    final sources = <String>{};
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
          sources.add(file.path);
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
    await _discardPickerCopies(sources);
  }

  Future<void> _discardPickerCopies(Set<String> sources) async {
    final pickerDirectory = _pickerDirectory;
    if (pickerDirectory == null || sources.isEmpty) return;
    final String root;
    try {
      root = await (await pickerDirectory()).resolveSymbolicLinks();
    } catch (_) {
      return;
    }
    for (final source in sources) {
      try {
        final resolved = await File(source).resolveSymbolicLinks();
        // La captura ya se guardó. Borra solo las copias temporales de la app.
        if (p.isWithin(root, resolved)) await File(resolved).delete();
      } on FileSystemException {
        // Un archivo pudo desaparecer mientras se guardaba la captura.
      }
    }
  }

  Future<CaptureReadResult> list(
    String account, {
    bool queuedOnly = false,
    String? id,
  }) async {
    final rows = await db.query(
      'captures',
      where: [
        'account = ? AND $_unexpired',
        if (id != null) 'id = ?',
        if (queuedOnly) 'id IN (SELECT id FROM outbox WHERE account = ?)',
      ].join(' AND '),
      whereArgs: [
        account,
        _now().millisecondsSinceEpoch,
        ?id,
        if (queuedOnly) account,
      ],
    );
    final entries = await Future.wait(
      rows.map((row) async {
        final id = row['id']! as String;
        final expiresAt = row['expires_at'] as int?;
        try {
          return (
            id,
            expiresAt,
            await _decodeCapture(account, id, row['body']!),
          );
        } catch (_) {
          return (id, expiresAt, null);
        }
      }),
    );
    final cutoff = _now().millisecondsSinceEpoch;
    final current = entries.where(
      (entry) => entry.$2 == null || entry.$2! > cutoff,
    );
    return (
      rows: [for (final (_, _, capture) in current) ?capture],
      unreadableIds: [
        for (final (id, _, capture) in current)
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
    final row = rows.single;
    final expiresAt = row['expires_at'] as int?;
    bool expired() =>
        expiresAt != null && expiresAt <= _now().millisecondsSinceEpoch;
    try {
      final capture = await _decodeCapture(account, id, row['body']!);
      return expired() ? null : capture;
    } catch (_) {
      if (expired()) return null;
      rethrow;
    }
  }

  Future<Capture> _decodeCapture(
    String account,
    String id,
    Object body,
  ) async => Capture.from(
    jsonDecode(utf8.decode(await _unseal(account, id, body))) as Map,
  );

  Future<bool> retryReviewedCapture(
    String account,
    String id, {
    required bool Function() authorized,
  }) async {
    final rows = await db.query(
      'captures',
      columns: ['body'],
      where: 'account = ? AND id = ? AND expires_at IS NULL',
      whereArgs: [account, id],
    );
    if (rows.isEmpty || !authorized()) return false;
    final previousBody = rows.single['body']!;
    final capture = await _decodeCapture(account, id, previousBody);
    if (capture['state'] != 'attention') return false;
    capture['state'] = 'pending';
    capture['attempts'] = 0;
    capture.remove('next_attempt');
    capture.remove('message');
    final body = await _seal(account, id, utf8.encode(jsonEncode(capture)));
    return db.transaction((tx) async {
      if (!authorized()) return false;
      // Otro reintento pudo haber enviado la captura durante el cifrado.
      final changed = await tx.update(
        'captures',
        {'body': body},
        where:
            'account = ? AND id = ? AND body = ? AND expires_at IS NULL '
            'AND id IN (SELECT id FROM outbox WHERE account = ?)',
        whereArgs: [account, id, previousBody, account],
      );
      if (changed != 0 && !authorized()) {
        throw StateError('La sesión cambió al reintentar la captura.');
      }
      return changed == 1;
    });
  }

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
        await tx.rawUpdate(
          'UPDATE incident_cache SET expires_at = MIN(expires_at, ('
          'SELECT expires_at FROM captures WHERE account = ? AND id = ?'
          ')) WHERE account = ? AND id = ?',
          [account, id, account, id],
        );
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

  Future<bool> cacheIncident(
    String account,
    Capture row, {
    bool Function()? authorized,
  }) async {
    final id = row['id'] as String;
    final started = _now();
    final original = await _incidentCaptureExpiry(db, account, id);
    final originalDeadline = original?.expiresAt;
    var deadline = started.add(_retention).millisecondsSinceEpoch;
    if (originalDeadline != null && originalDeadline < deadline) {
      deadline = originalDeadline;
    }
    if (deadline <= started.millisecondsSinceEpoch) return false;
    final body = await _seal(
      account,
      'cache/$id',
      utf8.encode(jsonEncode(row)),
    );
    return db.transaction((tx) async {
      final capture = await _incidentCaptureExpiry(tx, account, id);
      // Una descarga independiente puede existir sin captura. Si dependía de
      // una captura que desapareció durante el guardado, no restaura su copia.
      if (original != null && capture == null) return false;
      final captureDeadline = capture?.expiresAt;
      final currentTime = _now().millisecondsSinceEpoch;
      if (captureDeadline != null && captureDeadline < deadline) {
        deadline = captureDeadline;
      }
      if (deadline <= currentTime || authorized?.call() == false) return false;
      await tx.insert('incident_cache', {
        'account': account,
        'id': id,
        'body': body,
        'expires_at': deadline,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      if (authorized?.call() == false) {
        throw StateError('La sesión cambió al guardar el incidente.');
      }
      return true;
    });
  }

  Future<({int? expiresAt})?> _incidentCaptureExpiry(
    DatabaseExecutor db,
    String account,
    String id,
  ) async {
    final rows = await db.query(
      'captures',
      columns: ['expires_at'],
      where: 'account = ? AND id = ?',
      whereArgs: [account, id],
    );
    return rows.isEmpty ? null : (expiresAt: rows.single['expires_at'] as int?);
  }

  Future<Capture?> cachedIncident(String account, String id) async {
    final rows = await db.query(
      'incident_cache',
      where: 'account = ? AND id = ? AND expires_at > ?',
      whereArgs: [account, id, _now().millisecondsSinceEpoch],
    );
    if (rows.isEmpty) return null;
    final result = Capture.from(
      jsonDecode(
            utf8.decode(
              await _unseal(account, 'cache/$id', rows.single['body']!),
            ),
          )
          as Map,
    );
    return (rows.single['expires_at'] as int) > _now().millisecondsSinceEpoch
        ? result
        : null;
  }
}
