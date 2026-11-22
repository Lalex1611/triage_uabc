import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
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
  Object? failure;
  bool incompleteConfirmation = false;
  Completer<void>? hold;
  void Function()? afterCreate;
  @override
  Future<Capture> create(
    String account,
    String kind,
    String id,
    Capture payload,
  ) async {
    calls.add(id);
    await hold?.future;
    if (failure != null) throw failure!;
    if (incompleteConfirmation) return {};
    final result = records.putIfAbsent(id, () {
      order.add(kind);
      return {'id': 'remote-$id', if (kind == 'patient') 'code': 'ABC234'};
    });
    afterCreate?.call();
    if (loseResponse) {
      loseResponse = false;
      throw TimeoutException('response lost');
    }
    return result;
  }

  @override
  Future<void> upload(
    String kind,
    String id,
    Capture photo,
    Uint8List bytes,
  ) async {
    objects.add('$id/${photo['id']}');
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
    if (failLink) throw TimeoutException('link unavailable');
    links.add('$id/${photo['id']}');
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
  String? account;
  var generation = 0;
  Future<void> reopen() async {
    db = await databaseFactoryFfi.openDatabase(
      '${directory.path}/test.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: OfflineCaptureStore.createSchema,
      ),
    );
    store = OfflineCaptureStore(db, (_) async => key);
  }

  ParamedicoSyncService engine() => ParamedicoSyncService(
    store: store,
    remote: remote,
    currentAccount: () => account,
    sessionGeneration: () => generation,
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
    remote = FakeRemote();
    await reopen();
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

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
      expect(await store.list('bob'), isEmpty);
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
    expect(await store.list('alice'), isEmpty);
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
  test('account changes during upload stop subsequent operations', () async {
    await enqueue([draft('i'), draft('p', kind: 'patient', parent: 'i')]);
    remote.afterCreate = () {
      account = 'bob';
      generation++;
    };
    await engine().sync(force: true);
    expect(remote.calls, ['i']);
    expect(await store.list('bob'), isEmpty);
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
    await engine().sync();
    expect(remote.calls, ['i']);
    await engine().sync(force: true);
    expect(remote.calls, ['i', 'i']);
  });
  test('ciphertext cannot be reassigned to a different account', () async {
    await enqueue([draft('i')]);
    await db.update('captures', {'account': 'bob'});
    await expectLater(
      store.list('bob'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
  test('incomplete server confirmation never marks a capture synced', () async {
    await enqueue([draft('p', kind: 'patient')]);
    remote.incompleteConfirmation = true;
    await engine().sync(force: true);
    expect((await store.get('alice', 'p'))!['state'], 'attention');
    expect(await db.query('outbox'), hasLength(1));
  });
}
