import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/data/offline/offline_capture_store.dart';
import 'package:sistema_triage/features/paramedico/data/offline/paramedico_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeRemote implements CaptureRemote {
  final records = <String, Capture>{};
  final objects = <String>{};
  final links = <String>{};
  final order = <String>[];
  final calls = <String>[];
  bool loseResponse = false;
  bool loseUploadResponse = false;
  bool failLink = false;
  Object? linkFailure;
  Object? failure;
  bool incompleteConfirmation = false;
  bool codeExpired = false;
  String Function(String id) recordId = (id) => 'remote-$id';
  Completer<void>? hold;
  void Function()? beforeCreate;
  Completer<void>? uploadStarted;
  Completer<void>? holdUpload;
  int linkAttempts = 0;
  void Function()? afterCreate;
  @override
  Future<Capture> create(
    String account,
    String kind,
    String id,
    Capture payload,
  ) async {
    calls.add(id);
    beforeCreate?.call();
    await hold?.future;
    if (failure != null) throw failure!;
    if (incompleteConfirmation) return {};
    final result = records.putIfAbsent(id, () {
      order.add(kind);
      return {'id': recordId(id), if (kind == 'patient') 'code': 'ABC234'};
    });
    afterCreate?.call();
    if (loseResponse) {
      loseResponse = false;
      throw TimeoutException('response lost');
    }
    return kind == 'patient' && codeExpired
        ? {...result, 'code': null}
        : result;
  }

  @override
  Future<void> upload(
    String kind,
    String id,
    Capture photo,
    Uint8List bytes,
  ) async {
    objects.add('$id/${photo['id']}');
    uploadStarted?.complete();
    await holdUpload?.future;
    if (loseUploadResponse) {
      loseUploadResponse = false;
      throw TimeoutException('upload response lost');
    }
  }

  @override
  Future<void> link(
    String account,
    String kind,
    String id,
    Capture photo,
  ) async {
    linkAttempts++;
    if (linkFailure != null) throw linkFailure!;
    if (failLink) throw TimeoutException('link unavailable');
    final path = '$id/${photo['id']}';
    if (!objects.contains(path)) {
      throw const PostgrestException(message: 'Foto ausente', code: 'P0801');
    }
    links.add(path);
  }

  @override
  Future<void> discardRemovedIncidentPhoto(
    String remoteId,
    Capture photo,
  ) async {
    objects.remove('$remoteId/${photo['id']}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late Database db;
  late OfflineCaptureStore store;
  late SecretKey key;
  late FakeRemote remote;
  late DateTime now;
  String? account;
  var generation = 0;
  Future<void> reopen() async {
    db = await databaseFactoryFfi.openDatabase(
      '${directory.path}/test.db',
      options: OpenDatabaseOptions(
        version: OfflineCaptureStore.schemaVersion,
        onCreate: OfflineCaptureStore.createSchema,
      ),
    );
    store = OfflineCaptureStore(db, (_) async => key, now: () => now);
  }

  ParamedicoSyncService engine() => ParamedicoSyncService(
    store: store,
    remote: remote,
    currentAccount: () => account,
    sessionGeneration: () => generation,
    now: () => now,
  );
  Capture draft(String id, {String kind = 'incident', String? parent}) =>
      OfflineCaptureStore.draft(
        id: id,
        kind: kind,
        parentId: parent,
        payload: {'title': 'Dato clínico ficticio', 'incident_id': parent},
      );
  Future<void> enqueue(
    List<Capture> rows, {
    Map<String, List<String>> files = const {},
  }) =>
      store.enqueue('alice', rows, files, authorized: () => account == 'alice');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('triage_offline_test_');
    key = await AesGcm.with256bits().newSecretKey();
    account = 'alice';
    generation = 0;
    now = DateTime.utc(2026, 11, 23);
    remote = FakeRemote();
    await reopen();
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('la apertura fallida se comparte y permite reintentar', () async {
    const channel = MethodChannel('triage/offline_storage');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final firstResult = Completer<String?>();
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return calls == 1 ? firstResult.future : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final first = OfflineCaptureStore.open();
    expect(OfflineCaptureStore.open(), same(first));
    final firstFailure = expectLater(first, throwsStateError);
    firstResult.complete(null);
    await firstFailure;
    expect(calls, 1);
    final retry = OfflineCaptureStore.open();
    expect(retry, isNot(same(first)));
    await expectLater(retry, throwsStateError);
    expect(calls, 2);
  });

  test(
    'borra solo la copia temporal después de confirmar la captura',
    () async {
      final picker = await Directory('${directory.path}/picker').create();
      final copy = await File('${picker.path}/copia.jpg').writeAsBytes([1]);
      final original = await File(
        '${directory.path}/original.jpg',
      ).writeAsBytes([2]);
      final managedStore = OfflineCaptureStore(
        db,
        (_) async => key,
        pickerDirectory: () async => picker,
      );
      final attachments = {
        'i': [copy.path, original.path],
      };
      await expectLater(
        managedStore.enqueue(
          'alice',
          [draft('i')],
          attachments,
          authorized: () => false,
        ),
        throwsStateError,
      );
      expect(await copy.exists(), isTrue);
      expect(await db.query('captures'), isEmpty);

      await managedStore.enqueue(
        'alice',
        [draft('i')],
        attachments,
        authorized: () => true,
      );
      expect(await copy.exists(), isFalse);
      expect(await original.exists(), isTrue);
      expect(await db.query('attachments'), hasLength(2));
    },
  );

  test(
    'capture, outbox and photo survive closing SQLite and are encrypted',
    () async {
      final file = File('${directory.path}/photo.jpg');
      await file.writeAsBytes(utf8.encode('photo ficticia'));
      await enqueue(
        [draft('i')],
        files: {
          'i': [file.path],
        },
      );
      final raw = (await db.query('captures')).single['body'] as Uint8List;
      expect(
        utf8.decode(raw, allowMalformed: true),
        isNot(contains('Dato clínico')),
      );
      await db.close();
      await reopen();
      final row = (await store.get('alice', 'i'))!;
      expect(row['payload']['title'], 'Dato clínico ficticio');
      expect(
        await store.attachment('alice', row['photos'][0]['id']),
        utf8.encode('photo ficticia'),
      );
      expect(await db.query('outbox'), hasLength(1));
      expect((await store.list('bob')).rows, isEmpty);
    },
  );
  test('missing attachment rolls back incident and patient together', () async {
    await expectLater(
      enqueue(
        [draft('i'), draft('p', kind: 'patient', parent: 'i')],
        files: {
          'p': ['${directory.path}/missing.jpg'],
        },
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect((await store.list('alice')).rows, isEmpty);
    expect(await db.query('outbox'), isEmpty);
  });
  test(
    'storage failure during outbox insert rolls back capture and files',
    () async {
      await db.execute(
        "CREATE TRIGGER disk_full BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT, 'disk full'); END",
      );
      await expectLater(
        enqueue([draft('i')]),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('captures'), isEmpty);
      expect(await db.query('attachments'), isEmpty);
    },
  );
  test(
    'lost server response reuses id after restart without duplicate or new code',
    () async {
      await enqueue([draft('p', kind: 'patient')]);
      remote.loseResponse = true;
      await engine().sync(force: true);
      expect(remote.records, hasLength(1));
      expect((await store.get('alice', 'p'))!['state'], 'pending');
      await db.close();
      await reopen();
      await engine().sync(force: true);
      expect(remote.records, hasLength(1));
      expect(remote.calls, ['p', 'p']);
      expect((await store.get('alice', 'p'))!['code'], 'ABC234');
    },
  );
  test(
    'incidents precede patients and resolved relationship persists',
    () async {
      await enqueue([draft('p', kind: 'patient', parent: 'i'), draft('i')]);
      await engine().sync(force: true);
      expect(remote.order, ['incident', 'patient']);
      expect(
        (await store.get('alice', 'p'))!['payload']['incident_id'],
        'remote-i',
      );
    },
  );
  test('envía al paciente aunque se rechace la foto del incidente', () async {
    final photo = await File(
      '${directory.path}/photo.jpg',
    ).writeAsBytes([1, 2, 3]);
    await enqueue(
      [draft('i'), draft('p', kind: 'patient', parent: 'i')],
      files: {
        'i': [photo.path],
      },
    );
    remote.linkFailure = const PostgrestException(
      code: '42501',
      message: 'Foto no autorizada',
    );

    await engine().sync(force: true);

    final incident = (await store.get('alice', 'i'))!;
    expect(incident['state'], 'attention');
    expect(incident['remote_id'], 'remote-i');
    expect(await db.query('attachments'), hasLength(1));
    final patient = (await store.get('alice', 'p'))!;
    expect(patient['state'], 'synced');
    expect(patient['payload']['incident_id'], 'remote-i');
    expect(remote.order, ['incident', 'patient']);
  });
  test('keeps synced captures for 24 hours from confirmation', () async {
    await enqueue([draft('incident')]);
    now = now.add(const Duration(days: 3));
    await engine().sync(force: true);
    await enqueue([
      draft('pending', kind: 'patient', parent: 'incident'),
      draft('attention')..['state'] = 'attention',
    ]);
    now = now.add(const Duration(hours: 23, minutes: 59));
    await store.cacheIncident('alice', {'id': 'incident'});
    await store.cacheIncident('bob', {'id': 'incident'});
    await store.purgeExpired();
    expect(await store.get('alice', 'incident'), isNotNull);
    expect(await store.cachedIncident('alice', 'incident'), isNotNull);

    now = now.add(const Duration(minutes: 1));
    await db.close();
    await reopen();
    expect(await store.get('alice', 'incident'), isNull);
    await store.purgeExpired();
    expect(await db.query('captures', columns: ['id'], orderBy: 'id'), [
      {'id': 'attention'},
      {'id': 'pending'},
    ]);
    expect(await db.query('outbox'), hasLength(2));
    expect(await store.hasPending('alice'), isTrue);
    expect(await store.cachedIncident('alice', 'incident'), isNull);
    expect(await store.cachedIncident('bob', 'incident'), isNotNull);
  });

  test('una copia descargada sin captura local caduca en 24 horas', () async {
    await enqueue([draft('i')]);
    await engine().sync(force: true);
    now = now.add(const Duration(hours: 24));
    await store.purgeExpired();
    expect(await store.get('alice', 'i'), isNull);

    expect(await store.cacheIncident('alice', {'id': 'i'}), isTrue);
    expect(await store.cachedIncident('alice', 'i'), isNotNull);
    now = now.add(const Duration(hours: 24));
    expect(await store.cachedIncident('alice', 'i'), isNull);
    await store.purgeExpired();
    expect(await db.query('incident_cache'), isEmpty);
  });

  test('un guardado en curso no revive la copia local vencida', () async {
    await enqueue([draft('i')]);
    await engine().sync(force: true);
    now = now.add(const Duration(hours: 23));
    final startedEncryption = Completer<void>();
    final pendingKey = Completer<SecretKey>();
    final pendingStore = OfflineCaptureStore(db, (_) {
      startedEncryption.complete();
      return pendingKey.future;
    }, now: () => now);
    final write = pendingStore.cacheIncident('alice', {'id': 'i'});
    await startedEncryption.future;
    now = now.add(const Duration(hours: 1));
    await store.purgeExpired();
    pendingKey.complete(key);

    expect(await write, isFalse);
    expect(await db.query('incident_cache'), isEmpty);
  });

  test('actualizar SQLite elimina solo las copias sin vencimiento', () async {
    await enqueue([draft('pending')]);
    // Reproduce la tabla de caché de la versión anterior.
    await db.execute('DROP TABLE incident_cache');
    await db.execute(
      'CREATE TABLE incident_cache (account TEXT NOT NULL, id TEXT NOT NULL, '
      'body BLOB NOT NULL, PRIMARY KEY(account,id))',
    );
    await db.insert('incident_cache', {
      'account': 'alice',
      'id': 'viejo',
      'body': Uint8List.fromList([0]),
    });
    await db.setVersion(2);
    await db.close();
    db = await databaseFactoryFfi.openDatabase(
      '${directory.path}/test.db',
      options: OpenDatabaseOptions(
        version: OfflineCaptureStore.schemaVersion,
        onUpgrade: OfflineCaptureStore.upgradeSchema,
      ),
    );
    store = OfflineCaptureStore(db, (_) async => key, now: () => now);

    expect(await db.query('incident_cache'), isEmpty);
    expect(await store.hasPending('alice'), isTrue);
    expect(await store.get('alice', 'pending'), isNotNull);
    expect(await store.cacheIncident('alice', {'id': 'nuevo'}), isTrue);
    expect(await store.cachedIncident('alice', 'nuevo'), isNotNull);
  });

  test('patient can still sync after its confirmed incident expires', () async {
    remote.recordId = (id) => id;
    await enqueue([draft('incident')]);
    await engine().sync(force: true);
    await enqueue([draft('patient', kind: 'patient', parent: 'incident')]);

    now = now.add(const Duration(hours: 24));
    await store.purgeExpired();
    await engine().sync(force: true);
    final patient = await store.get('alice', 'patient');
    expect(patient?['state'], 'synced');
    expect(patient?['payload']['incident_id'], 'incident');
    expect(remote.calls, ['incident', 'patient']);
  });

  test('repeated retry buttons share one batch', () async {
    await enqueue([draft('i')]);
    remote.hold = Completer<void>();
    final sync = engine();
    final a = sync.sync(force: true);
    final b = sync.sync(force: true);
    expect(identical(a, b), isTrue);
    remote.hold!.complete();
    await Future.wait([a, b]);
    expect(remote.calls, ['i']);
  });
  test('el reintento manual espera un único lote forzado', () async {
    await enqueue([draft('active'), draft('later')]);
    final delayed = (await store.get('alice', 'later'))!;
    delayed['next_attempt'] = now
        .add(const Duration(hours: 1))
        .toIso8601String();
    await store.save('alice', delayed);
    final holdFollowUp = Completer<void>();
    remote.afterCreate = () => remote.hold = holdFollowUp;
    final service = engine();

    final automatic = service.sync();
    final forced = service.sync(force: true);
    expect(service.sync(), same(automatic));
    expect(service.sync(force: true), same(forced));
    expect(forced, isNot(same(automatic)));
    await automatic;
    expect(service.sync(force: true), same(forced));
    holdFollowUp.complete();
    await forced;
    expect(remote.calls, ['active', 'later']);
    expect(service.syncing, isFalse);
  });

  test('descarta el reintento forzado si cambia la sesión', () async {
    await enqueue([draft('active'), draft('later')]);
    remote.afterCreate = () => generation++;
    final service = engine();
    final automatic = service.sync();
    final forced = service.sync(force: true);
    await Future.wait([automatic, forced]);
    expect(remote.calls, ['active']);
    expect(await store.hasPending('alice'), isTrue);
  });

  test('el reintento de otra cuenta espera su propio lote', () async {
    await enqueue([draft('alice-incident')]);
    await store.enqueue(
      'bob',
      [draft('bob-incident')],
      {},
      authorized: () => true,
    );
    final delayed = (await store.get('bob', 'bob-incident'))!;
    delayed['next_attempt'] = now
        .add(const Duration(hours: 1))
        .toIso8601String();
    await store.save('bob', delayed);
    final hold = Completer<void>();
    final started = Completer<void>();
    remote.beforeCreate = () {
      if (!started.isCompleted) started.complete();
    };
    remote.hold = hold;
    final service = engine();
    final first = service.sync(force: true);
    await started.future;
    account = 'bob';
    generation++;
    final second = service.sync(force: true);
    expect(second, isNot(same(first)));
    expect(service.sync(force: true), same(second));
    hold.complete();
    await Future.wait([first, second]);
    expect(remote.calls, ['alice-incident', 'bob-incident']);
    expect((await store.get('bob', 'bob-incident'))?['state'], 'synced');
  });

  test('espera la cuenta original antes de vincular una foto subida', () async {
    final file = await File('${directory.path}/foto.jpg').writeAsBytes([1]);
    await enqueue(
      [draft('i')],
      files: {
        'i': [file.path],
      },
    );
    final started = remote.uploadStarted = Completer<void>();
    final hold = remote.holdUpload = Completer<void>();
    final service = engine();
    final first = service.sync(force: true);
    await started.future;
    account = 'bob';
    generation++;
    hold.complete();
    await first;
    expect(remote.linkAttempts, 0);
    account = 'alice';
    generation++;
    await service.sync(force: true);
    expect(remote.linkAttempts, 1);
    expect(remote.links, hasLength(1));
  });

  test('elimina de Storage la foto retirada que se volvió a subir', () async {
    final file = await File('${directory.path}/foto.jpg').writeAsBytes([1]);
    await enqueue(
      [draft('i')],
      files: {
        'i': [file.path],
      },
    );
    remote.linkFailure = const PostgrestException(
      code: 'P0802',
      message: 'Retirada',
    );
    await engine().sync(force: true);
    final capture = (await store.get('alice', 'i'))!;
    final photo = (capture['photos'] as List).single as Capture;
    expect(remote.linkAttempts, 1);
    expect(remote.objects, isEmpty);
    expect(remote.links, isEmpty);
    expect(photo['linked'], isFalse);
    expect(photo['removed'], isTrue);
    expect(capture['state'], 'synced');
    expect(await db.query('attachments'), isEmpty);
  });

  test(
    'el paciente confirmado envía su foto si el incidente es ilegible',
    () async {
      final file = await File('${directory.path}/foto.jpg').writeAsBytes([1]);
      await enqueue(
        [draft('i'), draft('p', kind: 'patient', parent: 'i')],
        files: {
          'p': [file.path],
        },
      );
      final patient = (await store.get('alice', 'p'))!;
      patient['remote_id'] = 'remote-p';
      await store.save('alice', patient);
      await db.update(
        'captures',
        {'body': Uint8List(40)},
        where: 'id = ?',
        whereArgs: ['i'],
      );
      await engine().sync(force: true);
      expect(remote.calls, isEmpty);
      expect(remote.links.single, startsWith('remote-p/'));
      expect((await store.get('alice', 'p'))?['state'], 'synced');
    },
  );

  test('account changes during upload stop subsequent operations', () async {
    await enqueue([draft('i'), draft('p', kind: 'patient', parent: 'i')]);
    remote.afterCreate = () {
      account = 'bob';
      generation++;
    };
    await engine().sync(force: true);
    expect(remote.calls, ['i']);
    expect((await store.list('bob')).rows, isEmpty);
    account = 'alice';
    generation++;
    remote.afterCreate = null;
    await engine().sync(force: true);
    expect(remote.calls, ['i', 'p']);
  });
  test(
    'process death with syncing checkpoint resumes from confirmed record',
    () async {
      await enqueue([draft('i')]);
      final row = (await store.get('alice', 'i'))!;
      row['state'] = 'syncing';
      row['remote_id'] = 'remote-i';
      await store.save('alice', row);
      await db.close();
      await reopen();
      await engine().sync(force: true);
      expect(remote.calls, isEmpty);
      expect((await store.get('alice', 'i'))!['state'], 'synced');
    },
  );
  test('repone la foto perdida en Storage desde el archivo cifrado', () async {
    final file = await File(
      '${directory.path}/photo.jpg',
    ).writeAsBytes([1, 2, 3]);
    await enqueue(
      [draft('incident')],
      files: {
        'incident': [file.path],
      },
    );
    remote.failLink = true;
    await engine().sync(force: true);
    final capture = (await store.get('alice', 'incident'))!;
    expect(capture['photos'][0]['uploaded'], isTrue);
    expect(await db.query('attachments'), hasLength(1));

    remote.objects.clear();
    remote.failLink = false;
    await engine().sync(force: true);

    expect(remote.objects, hasLength(1));
    expect(remote.links, remote.objects);
    expect(remote.calls, ['incident']);
    expect(await db.query('attachments'), isEmpty);
    expect(await db.query('outbox'), isEmpty);
  });

  test(
    'lost photo response and failed link keep encrypted copy until all confirmed',
    () async {
      final file = File('${directory.path}/photo.jpg');
      await file.writeAsBytes([1, 2, 3]);
      await enqueue(
        [draft('i')],
        files: {
          'i': [file.path],
        },
      );
      remote.loseUploadResponse = true;
      await engine().sync(force: true);
      expect(await db.query('attachments'), hasLength(1));
      remote.failLink = true;
      await engine().sync(force: true);
      final row = (await store.get('alice', 'i'))!;
      expect(row['photos'][0]['uploaded'], true);
      expect(row['photos'][0]['linked'], false);
      await db.close();
      await reopen();
      remote.failLink = false;
      await engine().sync(force: true);
      expect(remote.objects, hasLength(1));
      expect(remote.links, hasLength(1));
      expect(await db.query('attachments'), isEmpty);
      expect(await db.query('outbox'), isEmpty);
    },
  );
  test('permission rejection requires attention and is not retried', () async {
    await enqueue([draft('i'), draft('p', kind: 'patient', parent: 'i')]);
    remote.failure = const PostgrestException(message: 'denied', code: '42501');
    final sync = engine();
    await sync.sync(force: true);
    await sync.sync(force: true);
    expect(remote.calls, ['i']);
    expect((await store.get('alice', 'i'))!['state'], 'attention');
    expect((await store.get('alice', 'p'))!['remote_id'], isNull);
  });
  test(
    'expired authentication pauses until same account reauthenticates',
    () async {
      await enqueue([draft('i')]);
      remote.failure = const AuthException('expired');
      final sync = engine();
      await sync.sync(force: true);
      await sync.sync(force: true);
      expect(remote.calls, ['i']);
      remote.failure = null;
      generation++;
      await sync.sync(force: true);
      expect(remote.calls, ['i', 'i']);
    },
  );
  test('temporary errors respect persisted backoff', () async {
    await enqueue([draft('i')]);
    remote.failure = TimeoutException('network');
    await engine().sync();
    final retry = DateTime.parse(
      (await store.get('alice', 'i'))!['next_attempt'] as String,
    );
    now = retry.subtract(const Duration(milliseconds: 1));
    await engine().sync();
    expect(remote.calls, ['i']);
    now = retry;
    await engine().sync();
    expect(remote.calls, ['i', 'i']);
  });
  test('ciphertext cannot be reassigned to a different account', () async {
    await enqueue([draft('i')]);
    await db.update('captures', {'account': 'bob'});
    final result = await store.list('bob');
    expect(result.rows, isEmpty);
    expect(result.unreadableIds, ['i']);
  });
  test(
    'conserva una captura ilegible y sincroniza las independientes',
    () async {
      final file = await File(
        '${directory.path}/photo.jpg',
      ).writeAsBytes([1, 2, 3]);
      await enqueue(
        [
          draft('bad'),
          draft('bad-json'),
          draft('child', kind: 'patient', parent: 'bad'),
          draft('good'),
        ],
        files: {
          'bad': [file.path],
        },
      );
      await db.update(
        'captures',
        {'body': Uint8List(40)},
        where: 'id = ?',
        whereArgs: ['bad'],
      );
      final malformed = await AesGcm.with256bits().encrypt(
        utf8.encode('['),
        secretKey: key,
        aad: utf8.encode('alice/bad-json'),
      );
      await db.update(
        'captures',
        {'body': Uint8List.fromList(malformed.concatenation())},
        where: 'id = ?',
        whereArgs: ['bad-json'],
      );
      final result = await store.list('alice');
      expect(
        result.rows.map((row) => row['id']),
        unorderedEquals(['child', 'good']),
      );
      expect(result.unreadableIds, unorderedEquals(['bad', 'bad-json']));

      await engine().sync(force: true);

      expect(remote.calls, ['good']);
      expect(
        await db.query('outbox', columns: ['id']),
        unorderedEquals([
          {'id': 'bad'},
          {'id': 'bad-json'},
          {'id': 'child'},
        ]),
      );
      expect(await db.query('attachments'), hasLength(1));
      expect(
        (await store.list('alice')).unreadableIds,
        unorderedEquals(['bad', 'bad-json']),
      );
    },
  );
  test('omite la caché si la sesión cambia durante el cifrado', () async {
    final pendingKey = Completer<SecretKey>();
    final pendingStore = OfflineCaptureStore(db, (_) => pendingKey.future);
    var authorized = true;
    final pending = pendingStore.cacheIncident('alice', {
      'id': 'late',
    }, authorized: () => authorized);
    authorized = false;
    pendingKey.complete(key);
    await pending;
    expect(await store.cachedIncident('alice', 'late'), isNull);
  });
  test('omite una captura que vence durante el descifrado', () async {
    await enqueue([draft('i'), draft('unreadable'), draft('pending')]);
    final synced = (await store.get('alice', 'i'))!..['state'] = 'synced';
    final unreadable = (await store.get('alice', 'unreadable'))!
      ..['state'] = 'synced';
    await store.save('alice', synced);
    await store.save('alice', unreadable);
    await db.update(
      'captures',
      {'body': Uint8List(40)},
      where: 'id = ?',
      whereArgs: ['unreadable'],
    );
    now = now.add(const Duration(hours: 23));
    final reading = Completer<void>();
    final pendingKey = Completer<SecretKey>();
    var reads = 0;
    final delayed = OfflineCaptureStore(db, (_) {
      if (++reads == 4) reading.complete();
      return pendingKey.future;
    }, now: () => now);
    final single = delayed.get('alice', 'i');
    final multiple = delayed.list('alice');
    await reading.future;
    now = now.add(const Duration(hours: 1));
    pendingKey.complete(key);
    expect(await single, isNull);
    final result = await multiple;
    expect(result.rows.map((row) => row['id']), ['pending']);
    expect(result.unreadableIds, isEmpty);
  });
  test(
    'sincroniza la foto tras confirmar al paciente con código nulo',
    () async {
      final photo = await File(
        '${directory.path}/photo.jpg',
      ).writeAsBytes([1, 2, 3]);
      await enqueue(
        [draft('p', kind: 'patient')],
        files: {
          'p': [photo.path],
        },
      );
      remote.loseResponse = true;
      await engine().sync(force: true);
      remote.codeExpired = true;
      await engine().sync(force: true);

      final patient = (await store.get('alice', 'p'))!;
      expect(patient['state'], 'synced');
      expect(patient['code'], isNull);
      expect(remote.records, hasLength(1));
      expect(remote.links, hasLength(1));
      expect(await db.query('attachments'), isEmpty);
    },
  );
  test('incomplete server confirmation never marks a capture synced', () async {
    await enqueue([draft('p', kind: 'patient')]);
    remote.incompleteConfirmation = true;
    await engine().sync(force: true);
    expect((await store.get('alice', 'p'))!['state'], 'attention');
    expect(await db.query('outbox'), hasLength(1));
  });
}
