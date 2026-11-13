import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';

/// Incidentes activos con sus pacientes, compartidos por el mapa y la hoja de
/// incidentes: se cargan una vez y Supabase Realtime los mantiene al día
///
/// Mientras alguien escucha, está suscrito a los cambios de `incidents` y
/// `patients`; cuando deja de escucharlo el último, se desuscribe y olvida los
/// datos (p. ej. al cerrar sesión).
class ParamedicoIncidentsStore extends ChangeNotifier {
  ParamedicoIncidentsStore({ParamedicoIncidentsRepository? repository})
    : _repo = repository ?? ParamedicoIncidentsRepository();

  static final instance = ParamedicoIncidentsStore();

  /// Agrupa ráfagas de cambios (p. ej. un triage de varios pacientes) en una carga
  static const changeDebounce = Duration(milliseconds: 500);

  final ParamedicoIncidentsRepository _repo;

  List<ParamedicoIncidentSummary> incidents = const [];
  Map<String, IncidentPatientTriageCounts> counts = const {};
  Map<String, List<MapPatientPin>> patientsByIncident = const {};
  Map<String, double> radiusMetersByIncident = const {};

  /// Ya hubo una carga buena; las siguientes actualizan sin cargador
  bool loaded = false;

  /// Solo si nunca se pudo cargar: con datos, un fallo posterior los conserva
  String? error;

  Future<void> Function()? _unwatch;
  bool _listening = false;
  Timer? _debounce;
  Future<void>? _running;
  Future<void>? _queued;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_listening) return;
    _listening = true;
    _watch();
    unawaited(refresh());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners && _listening) _stop();
  }

  /// Vuelve a pedir los datos. Si ya hay una carga en curso, encola una sola
  /// más: lo que pidió quien llama puede haber cambiado después de que empezara
  Future<void> refresh() {
    final running = _running;
    if (running == null) {
      return _running = _load().whenComplete(() => _running = null);
    }
    return _queued ??= running.then((_) {
      _queued = null;
      return refresh();
    });
  }

  void _watch() {
    var subscribedBefore = false;
    try {
      _unwatch = _repo.watchIncidentsAndPatients(
        onChange: _scheduleRefresh,
        // La primera vez ya se está cargando; al reconectar sí hace falta
        onSubscribed: () {
          if (subscribedBefore) _scheduleRefresh();
          subscribedBefore = true;
        },
      );
    } catch (e) {
      // Sin Supabase o sin conexión: los datos llegan igual con cada recarga
      debugPrint('Sin tiempo real para incidentes: $e');
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(changeDebounce, () => unawaited(refresh()));
  }

  void _stop() {
    _listening = false;
    _debounce?.cancel();
    final unwatch = _unwatch;
    _unwatch = null;
    if (unwatch != null) unawaited(unwatch());
    incidents = const [];
    counts = const {};
    patientsByIncident = const {};
    radiusMetersByIncident = const {};
    loaded = false;
    error = null;
  }

  Future<void> _load() async {
    try {
      final list = await _repo.listOpenIncidents();
      final centers = <String, LatLng>{
        for (final inc in list)
          if (inc.latitude != null && inc.longitude != null)
            inc.id: LatLng(inc.latitude!, inc.longitude!),
      };
      final patients = await _repo.patientsOverviewForIncidents(
        list.map((e) => e.id),
        incidentCentersById: centers,
      );
      // Si nadie escucha ya, no se guarda nada (se olvidó al desuscribirse)
      if (!_listening) return;
      final grouped = <String, List<MapPatientPin>>{};
      for (final pin in patients.pins) {
        grouped.putIfAbsent(pin.incidentId, () => []).add(pin);
      }
      incidents = list;
      counts = patients.counts;
      patientsByIncident = grouped;
      radiusMetersByIncident = {
        for (final e in centers.entries)
          e.key: MapIncidentCoverageService.radiusMeters(
            e.value,
            grouped[e.key] ?? const [],
          ),
      };
      loaded = true;
      error = null;
    } catch (e) {
      if (!_listening) return;
      if (!loaded) error = e.toString();
    }
    notifyListeners();
  }

  /// Busca un incidente activo por id en lo ya cargado
  ParamedicoIncidentSummary? byId(String id) {
    for (final e in incidents) {
      if (e.id == id) return e;
    }
    return null;
  }
}
