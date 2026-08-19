import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprueba si el dispositivo tiene enlace de red (Wi‑Fi o datos móviles)
class DeviceConnectivityService {
  DeviceConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  bool _hasConnection = true;

  bool get hasConnection => _hasConnection;

  Stream<bool> get onConnectionChanged => _changes.stream;

  static bool resultsIndicateOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    return resultsIndicateOnline(results);
  }

  void startListening() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _apply(resultsIndicateOnline(results));
    });
    unawaited(
      checkNow().then(_apply),
    );
  }

  void _apply(bool online) {
    if (_hasConnection == online) return;
    _hasConnection = online;
    if (!_changes.isClosed) {
      _changes.add(online);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _changes.close();
  }
}
