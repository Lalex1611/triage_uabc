import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:sistema_triage/core/connectivity/app_connectivity_notifier.dart';
import 'package:sistema_triage/core/offline/offline_capture_store.dart';
import 'package:sistema_triage/core/offline/offline_sync_service.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

typedef MedicoOfflineSession = ({String account, String hospitalId});

class MedicoOfflineRuntime extends ChangeNotifier with WidgetsBindingObserver {
  MedicoOfflineRuntime._();

  static final instance = MedicoOfflineRuntime._();
  static const _walkIn = 'medico_walk_in';

  final _auth = AuthGate.instance;
  final _connectivity = AppConnectivityNotifier.instance;
  OfflineCaptureStore? _store;
  OfflineSyncService? _syncService;
  Timer? _timer;
  Future<void>? _batch;
  bool _active = true;
  String? _openError;

  bool get supported => Platform.isAndroid || Platform.isIOS;
  MedicoOfflineSession? get session => _auth.medicoOfflineSession;
  bool get canCapture => _store != null && session != null;
  bool get connected => _connectivity.isConnected;
  bool get syncing => _batch != null;
  String? get error => _openError ?? _syncService?.storageError;

  // Paramédico conserva las claves existentes. Médico se aísla por hospital.
  static String storageScope(MedicoOfflineSession session) =>
      'medico_${session.account}_${session.hospitalId}';

  Future<void> start() async {
    if (!supported || _store != null) return;
    try {
      final store = await OfflineCaptureStore.open();
      _store = store;
      _syncService = OfflineSyncService(
        store: store,
        remote: _MedicoCaptureRemote(Supabase.instance.client),
        currentAccount: () => _active ? session?.account : null,
        storageScope: (account) {
          final owner = session;
          return owner != null && owner.account == account
              ? storageScope(owner)
              : null;
        },
        sessionGeneration: () => _auth.sessionGeneration,
      )..addListener(notifyListeners);
      WidgetsBinding.instance.addObserver(this);
      _auth.addListener(_changed);
      _connectivity.addListener(_changed);
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _changed());
      _changed();
    } catch (_) {
      _openError = 'No se pudo abrir el almacenamiento protegido.';
      notifyListeners();
    }
  }

  void _changed() {
    notifyListeners();
    if (_active && connected && canCapture) unawaited(_synchronize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) unawaited(retryNow());
  }

  Future<void> _synchronize({bool force = false}) {
    if (_batch case final batch?) return batch;
    final owner = session;
    final store = _store;
    if (!_active || !connected || owner == null || store == null) {
      return Future.value();
    }

    _batch =
        Future<void>(() async {
          try {
            if (!await store.hasPending(storageScope(owner))) return;
          } catch (_) {
            _openError = 'No se pudieron consultar las capturas pendientes.';
            return;
          }
          _openError = null;
          await _auth.syncFromSession();
          if (_active &&
              connected &&
              _auth.lastVerificationSucceeded &&
              session == owner) {
            await _syncService!.sync(force: force);
          }
        }).whenComplete(() {
          _batch = null;
          notifyListeners();
        });
    notifyListeners();
    return _batch!;
  }

  Future<void> retryNow() async {
    await _connectivity.refresh();
    if (connected && session == null) await _auth.syncFromSession();
    await _batch;
    if (connected) await _synchronize(force: true);
  }

  Future<void> saveWalkIn({
    required String displayName,
    required String triageColor,
    required Map<String, dynamic> demographics,
    required Map<String, dynamic> vitalSigns,
    required String reason,
    required String? photoPath,
  }) async {
    final owner = session;
    final store = _store;
    if (owner == null || store == null) {
      throw StateError(error ?? 'Verifica tu sesión de Médico con conexión.');
    }
    final generation = _auth.sessionGeneration;
    final id = const Uuid().v4();
    final capture = OfflineCaptureStore.draft(
      id: id,
      kind: _walkIn,
      payload: {
        'display_name': displayName,
        'triage_color': triageColor,
        'hospital_id': owner.hospitalId,
        'demographics': {...demographics}..remove('photo_local_paths'),
        'vital_signs': vitalSigns,
        'descriptive_notes': reason,
      },
    );
    await store.enqueue(
      storageScope(owner),
      [capture],
      {
        id: [?photoPath],
      },
      authorized: () =>
          session == owner && generation == _auth.sessionGeneration,
    );
    _changed();
  }

  Future<List<Capture>> captures() async {
    final owner = session;
    final store = _store;
    if (owner == null || store == null) return [];
    final generation = _auth.sessionGeneration;
    final rows = await store.list(storageScope(owner));
    if (session != owner || generation != _auth.sessionGeneration) return [];
    return rows;
  }

  Future<void> retryReviewedCapture(String id) async {
    final owner = session;
    final store = _store;
    if (owner == null || store == null || syncing) return;
    final scope = storageScope(owner);
    _batch =
        Future<void>(() async {
          final row = await store.get(scope, id);
          if (session != owner || row == null || row['state'] != 'attention') {
            return;
          }
          row['state'] = 'pending';
          row['attempts'] = 0;
          row.remove('next_attempt');
          row.remove('message');
          await store.save(scope, row);
        }).whenComplete(() {
          _batch = null;
          notifyListeners();
        });
    notifyListeners();
    await _batch;
    await retryNow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_changed);
    _connectivity.removeListener(_changed);
    _syncService?.dispose();
    super.dispose();
  }
}

class _MedicoCaptureRemote extends SupabaseOfflineCaptureRemote {
  _MedicoCaptureRemote(super.client);

  @override
  Future<Capture> create(
    String account,
    String kind,
    String id,
    Capture payload,
  ) async => Capture.from(
    await client
            .rpc(
              'sync_medico_walk_in_capture',
              params: {
                'p_account_id': account,
                'p_sync_client_id': id,
                'p_payload': payload,
              },
            )
            .timeout(SupabaseOfflineCaptureRemote.timeout)
        as Map,
  );

  @override
  Future<void> link(
    String account,
    String kind,
    String remoteId,
    Capture photo,
  ) => client
      .rpc<void>(
        'link_medico_walk_in_photo',
        params: {
          'p_account_id': account,
          'p_patient_id': remoteId,
          'p_path': photoPath(remoteId, photo),
        },
      )
      .timeout(SupabaseOfflineCaptureRemote.timeout);
}
