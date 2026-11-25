import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/offline/offline_capture_store.dart';
import 'package:sistema_triage/core/offline/offline_sync_service.dart';
import 'package:sistema_triage/features/medico/data/offline/medico_offline_runtime.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const owner = (account: 'medico-a', hospitalId: 'hospital-a');
  final ownerScope = MedicoOfflineRuntime.storageScope(owner);
  late MedicoOfflineSession session;
  late OfflineCaptureStore store;
  late Database db;
  late _MedicoRemote remote;
  late OfflineSyncService service;

  setUp(() async {
    session = owner;
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: OfflineCaptureStore.schemaVersion,
        onCreate: OfflineCaptureStore.createSchema,
      ),
    );
    final key = await AesGcm.with256bits().newSecretKey();
    store = OfflineCaptureStore(db, (_) async => key);
    remote = _MedicoRemote();
    service = OfflineSyncService(
      store: store,
      remote: remote,
      currentAccount: () => session.account,
      storageScope: (_) => MedicoOfflineRuntime.storageScope(session),
      sessionGeneration: () => 0,
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  Future<void> enqueue({String? photoPath}) => store.enqueue(
    ownerScope,
    [
      OfflineCaptureStore.draft(
        id: 'alta-1',
        kind: 'medico_walk_in',
        payload: {
          'hospital_id': owner.hospitalId,
          'display_name': 'Paciente ficticio',
          'vital_signs': {'heart_rate': 72},
        },
      ),
    ],
    {
      'alta-1': [?photoPath],
    },
    authorized: () => true,
  );

  test('retoma el alta y adjunto con el mismo identificador', () async {
    final directory = await Directory.systemTemp.createTemp(
      'triage_medico_test_',
    );
    final photo = await File(
      '${directory.path}/photo.jpg',
    ).writeAsBytes([1, 2, 3]);
    addTearDown(() => directory.delete(recursive: true));
    await enqueue(photoPath: photo.path);

    remote.loseResponse = true;
    await service.sync(force: true);
    expect((await store.get(ownerScope, 'alta-1'))?['remote_id'], isNull);
    expect(await store.hasPending(ownerScope), isTrue);

    remote.failLink = true;
    await service.sync(force: true);
    final halfway = (await store.get(ownerScope, 'alta-1'))!;
    expect(halfway['state'], 'pending');
    expect(halfway['code'], 'MED234');
    expect(remote.records, hasLength(1));
    expect(remote.uploads, 1);

    remote.failLink = false;
    await service.sync(force: true);
    final confirmed = (await store.get(ownerScope, 'alta-1'))!;
    expect(confirmed['state'], 'synced');
    expect(confirmed['code'], 'MED234');
    expect(remote.accounts, [owner.account, owner.account]);
    expect(remote.uploads, 1);
    expect(remote.links, 1);
    expect(await store.hasPending(ownerScope), isFalse);
  });

  test('otra cuenta u otro hospital no envían el alta', () async {
    await enqueue();
    session = (account: owner.account, hospitalId: 'hospital-b');
    await service.sync(force: true);
    session = (account: 'medico-b', hospitalId: owner.hospitalId);
    await service.sync(force: true);
    expect(remote.accounts, isEmpty);
    expect(await store.hasPending(ownerScope), isTrue);

    session = owner;
    await service.sync(force: true);
    expect(remote.accounts, [owner.account]);
    expect((await store.get(ownerScope, 'alta-1'))?['state'], 'synced');
  });
}

class _MedicoRemote implements CaptureRemote {
  final records = <String, Capture>{};
  final accounts = <String>[];
  bool loseResponse = false;
  bool failLink = false;
  int uploads = 0;
  int links = 0;

  @override
  Future<Capture> create(
    String account,
    String kind,
    String id,
    Capture payload,
  ) async {
    accounts.add(account);
    expect(kind, 'medico_walk_in');
    expect(payload['hospital_id'], 'hospital-a');
    expect(payload['vital_signs'], {'heart_rate': 72});
    final result = records.putIfAbsent(
      id,
      () => {'id': 'servidor-1', 'code': 'MED234'},
    );
    if (loseResponse) {
      loseResponse = false;
      throw TimeoutException('Respuesta perdida');
    }
    return result;
  }

  @override
  Future<void> upload(
    String kind,
    String remoteId,
    Capture photo,
    Uint8List bytes,
  ) async {
    expect(bytes, [1, 2, 3]);
    uploads++;
  }

  @override
  Future<void> link(
    String account,
    String kind,
    String remoteId,
    Capture photo,
  ) async {
    if (failLink) throw TimeoutException('Vínculo pendiente');
    links++;
  }
}
