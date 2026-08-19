import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/services/device_connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Estado global de conectividad: red del dispositivo y alcance del backend (Supabase)
class AppConnectivityNotifier extends ChangeNotifier {
  AppConnectivityNotifier._();

  static final AppConnectivityNotifier instance = AppConnectivityNotifier._();

  final DeviceConnectivityService _device = DeviceConnectivityService();
  StreamSubscription<bool>? _deviceSub;
  StreamSubscription<AuthState>? _authSub;
  Timer? _pollTimer;
  bool _isConnected = true;
  bool _refreshing = false;

  bool get isConnected => _isConnected;
  bool get isRefreshing => _refreshing;

  String get statusMessage {
    if (!_isConnected) {
      return 'Sin conexión. Active Wi‑Fi o datos móviles para usar la aplicación.';
    }
    if (!SupabaseEnv.isConfigured) {
      return 'Conexión de red activa.';
    }
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (!hasSession) {
      return 'Conexión de red activa. Inicie sesión para sincronizar.';
    }
    return 'Conexión activa. La aplicación puede sincronizar con el servidor.';
  }

  Future<void> start() async {
    await _updateConnection();

    _device.startListening();
    _deviceSub = _device.onConnectionChanged.listen((_) {
      unawaited(_updateConnection());
    });
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_updateConnection());
    });

    if (SupabaseEnv.isConfigured) {
      _authSub ??= Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        unawaited(_updateConnection());
      });
    }

    // En Android la red / Supabase a veces no están listos en el primer frame
    unawaited(_scheduleStartupRechecks());
  }

  Future<void> _scheduleStartupRechecks() async {
    for (final delay in [
      const Duration(milliseconds: 600),
      const Duration(seconds: 2),
    ]) {
      await Future<void>.delayed(delay);
      await _updateConnection();
    }
  }

  Future<void> _updateConnection() async {
    final next = await _evaluateConnection();
    if (_isConnected != next) {
      _isConnected = next;
      notifyListeners();
    }
  }

  /// Fuerza una nueva comprobación (p. ej. al pulsar el ícono Wi‑Fi del header)
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    try {
      final next = await _evaluateConnection();
      if (_isConnected != next) {
        _isConnected = next;
      }
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<bool> _evaluateConnection() async {
    final deviceOnline = await _device.checkNow();
    if (!deviceOnline) return false;
    if (!SupabaseEnv.isConfigured) return true;

    return _probeBackend();
  }

  Future<bool> _probeBackend() async {
    try {
      final uri = Uri.parse(SupabaseEnv.projectUrl);
      final response = await http
          .get(uri, headers: {'apikey': SupabaseEnv.anonKey})
          .timeout(const Duration(seconds: 4));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  void disposeForTest() {
    _deviceSub?.cancel();
    _deviceSub = null;
    _authSub?.cancel();
    _authSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _device.dispose();
  }
}
