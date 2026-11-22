import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:sistema_triage/core/connectivity/app_connectivity_notifier.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/features/paramedico/data/offline/offline_capture_store.dart';
import 'package:sistema_triage/features/paramedico/data/offline/paramedico_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ParamedicoOfflineRuntime extends ChangeNotifier
    with WidgetsBindingObserver {
  ParamedicoOfflineRuntime._();
  static final instance = ParamedicoOfflineRuntime._();
  OfflineCaptureStore? store;
  ParamedicoSyncService? syncService;
  String? error;
  Timer? _timer;
  bool _active = true;
  Future<void>? _running;
  bool get supported => Platform.isAndroid || Platform.isIOS;
  String? get account => AuthGate.instance.offlineAccount;
  bool get canCapture => supported && store != null && account != null;
  bool get syncing => _running != null;
  bool get offline => !AppConnectivityNotifier.instance.isConnected;
  void refreshView() => notifyListeners();
  Future<void> retryReviewedCapture(String id) async {
    final owner = account;
    final row = await local(id);
    if (owner == null ||
        owner != account ||
        row == null ||
        row['state'] != 'attention') {
      return;
    }
    row['state'] = 'pending';
    row['attempts'] = 0;
    row.remove('next_attempt');
    row.remove('message');
    await store!.save(owner, row);
    notifyListeners();
    await retryNow();
  }

  Future<Uint8List> photoBytes(Capture capture, Capture photo) async {
    final owner = account;
    if (owner == null || store == null) {
      throw StateError('Sesión no disponible.');
    }
    final bytes = capture['state'] == 'synced'
        ? await Supabase.instance.client.storage
              .from(
                capture['kind'] == 'incident'
                    ? 'incident_photos'
                    : 'patient_photos',
              )
              .download(
                '${capture['remote_id']}/${photo['id']}.${photo['extension']}',
              )
              .timeout(const Duration(seconds: 10))
        : await store!.attachment(owner, photo['id'] as String);
    if (account != owner) throw StateError('La sesión cambió.');
    return bytes;
  }

  Future<void> start() async {
    if (!supported || store != null) return;
    try {
      store = await OfflineCaptureStore.open();
      syncService = ParamedicoSyncService(
        store: store!,
        remote: SupabaseCaptureRemote(Supabase.instance.client),
        currentAccount: () => _active ? account : null,
        sessionGeneration: () => AuthGate.instance.sessionGeneration,
      );
      syncService!.addListener(notifyListeners);
      WidgetsBinding.instance.addObserver(this);
      AuthGate.instance.addListener(_changed);
      AppConnectivityNotifier.instance.addListener(_changed);
      _timer = Timer.periodic(const Duration(seconds: 15), (_) {
        notifyListeners(); // hides local UI as soon as the session expires
        _changed();
      });
      _changed();
    } catch (_) {
      error =
          'No se pudo abrir el almacenamiento protegido. Comprueba el espacio y vuelve a abrir la app.';
    }
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    if (_active && !offline && account != null) unawaited(synchronize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) unawaited(retryNow());
  }

  Future<void> synchronize({bool force = false}) {
    if (_running != null) return _running!;
    if (!_active || syncService == null || account == null || offline) {
      return Future.value();
    }
    // Deferring one microtask installs the lock before auth notifies listeners.
    _running =
        Future<void>(() async {
          await AuthGate.instance.syncFromSession();
          if (AuthGate.instance.lastVerificationSucceeded &&
              account != null &&
              _active) {
            await syncService!.sync(force: force);
          }
        }).whenComplete(() {
          _running = null;
          notifyListeners();
        });
    notifyListeners();
    return _running!;
  }

  Future<void> retryNow() async {
    await AppConnectivityNotifier.instance.refresh();
    // refresh may have triggered an automatic batch: await it, then force due work.
    if (_running != null) await _running;
    if (!offline && account == null) await AuthGate.instance.syncFromSession();
    if (!offline) await synchronize(force: true);
  }

  Future<List<Capture>> captures() async {
    final owner = account;
    final generation = AuthGate.instance.sessionGeneration;
    if (owner == null || store == null) return [];
    final rows = await store!.list(owner);
    return account == owner && generation == AuthGate.instance.sessionGeneration
        ? rows
        : [];
  }

  Future<Capture?> local(String id) async {
    final owner = account;
    if (owner == null || store == null) return null;
    final row = await store!.get(owner, id);
    return owner == account ? row : null;
  }

  Future<Capture?> incident(String id) async {
    final owner = account;
    if (owner == null || store == null) return null;
    final row = await local(id);
    if (row == null) {
      final cached = await store!.cachedIncident(owner, id);
      return account == owner ? cached : null;
    }
    final data = Capture.from(row['payload'] as Map);
    return {
      'id': id,
      'generated_title': data['title'],
      'description': data['description'],
      'emergency_type': data['emergency_type'],
      'created_at': row['captured_at'],
      'created_by': owner,
      'status': 'activo',
      'photo_local_paths': <String>[],
      'location': {
        'coordinates': [data['lng'], data['lat']],
      },
    };
  }

  Future<void> cacheIncident(Capture row) async {
    final owner = account;
    if (owner != null && store != null) await store!.cacheIncident(owner, row);
  }

  Future<Capture> capture({
    required String kind,
    required Capture payload,
    List<String> photos = const [],
    String? parentId,
    Capture? quickIncident,
  }) async {
    final owner = account;
    final generation = AuthGate.instance.sessionGeneration;
    if (!canCapture || owner == null) {
      throw StateError(
        error ?? 'Autentícate como paramédico antes de capturar.',
      );
    }
    final entries = <Capture>[];
    if (quickIncident != null) {
      parentId = const Uuid().v4();
      entries.add(
        OfflineCaptureStore.draft(
          id: parentId,
          kind: 'incident',
          payload: quickIncident,
        ),
      );
      payload = {...payload, 'incident_id': parentId};
    } else if (parentId != null &&
        await store!.get(owner, parentId) == null &&
        await store!.cachedIncident(owner, parentId) == null) {
      throw StateError(
        'Abre este incidente con conexión antes de registrar pacientes sin red.',
      );
    }
    final id = const Uuid().v4();
    final row = OfflineCaptureStore.draft(
      id: id,
      kind: kind,
      payload: payload,
      parentId: parentId,
    );
    entries.add(row);
    try {
      await store!.enqueue(
        owner,
        entries,
        {id: photos},
        authorized: () =>
            account == owner &&
            AuthGate.instance.sessionGeneration == generation,
      );
    } on FormatException {
      rethrow;
    } on FileSystemException {
      rethrow;
    } catch (_) {
      throw StateError(
        'No se pudo guardar en este teléfono. Comprueba el espacio y la sesión; el formulario sigue abierto.',
      );
    }
    notifyListeners();
    // Local commit defines success; a remote failure cannot roll it back.
    _changed();
    return row;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AuthGate.instance.removeListener(_changed);
    AppConnectivityNotifier.instance.removeListener(_changed);
    syncService?.removeListener(notifyListeners);
    super.dispose();
  }
}
