import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';

/// Radio de cobertura y visibilidad de pacientes en el mapa interactivo
class MapIncidentCoverageService {
  MapIncidentCoverageService._();

  /// Radio mínimo cuando todos los pacientes están en el mismo punto que el incidente
  static const double minRadiusMeters = 18;

  /// Sin pacientes georreferenciados: solo marca el punto del incidente
  static const double defaultRadiusMeters = 28;

  /// Margen alrededor del paciente más lejano
  static const double radiusPaddingMeters = 8;

  /// Pacientes más lejos se ignoran para el radio (GPS de traslado, datos viejos)
  static const double maxPatientDistanceFromIncidentMeters = 120;

  static const double minZoomForPatients = 14;
  static const double minZoomForCoverageRing = 12;

  static const Distance _distance = Distance();

  /// Radio en metros hasta el paciente más lejano (+ margen). Sin inflar con mínimos grandes
  static double radiusMeters(LatLng incidentCenter, List<MapPatientPin> patients) {
    if (patients.isEmpty) return defaultRadiusMeters;

    var maxM = 0.0;
    for (final p in patients) {
      final m = _distance(
        incidentCenter,
        LatLng(p.latitude, p.longitude),
      );
      if (m > maxPatientDistanceFromIncidentMeters) continue;
      if (m > maxM) maxM = m;
    }

    if (maxM < 1) return minRadiusMeters;

    return maxM + radiusPaddingMeters;
  }

  /// Puntos en el borde del círculo de cobertura (para encuadrar el mapa)
  static List<LatLng> coverageExtentPoints(
    LatLng center,
    double radiusMeters,
  ) {
    if (radiusMeters <= 0) return [center];
    return [
      _distance.offset(center, radiusMeters, 0),
      _distance.offset(center, radiusMeters, 90),
      _distance.offset(center, radiusMeters, 180),
      _distance.offset(center, radiusMeters, 270),
    ];
  }

  /// Incidente + pacientes + borde del área de cobertura
  static List<LatLng> boundsPointsForIncident({
    required LatLng incidentCenter,
    required List<MapPatientPin> patients,
    required double radiusMeters,
  }) {
    final points = <LatLng>[incidentCenter];
    for (final p in patients) {
      points.add(LatLng(p.latitude, p.longitude));
    }
    points.addAll(coverageExtentPoints(incidentCenter, radiusMeters));
    return points;
  }

  static bool shouldShowCoverageRing({
    required double zoom,
    required String? selectedIncidentId,
    required String incidentId,
  }) {
    if (selectedIncidentId == incidentId) return true;
    return zoom >= minZoomForCoverageRing;
  }

  static bool shouldShowPatients({
    required double zoom,
    required LatLng cameraCenter,
    required LatLng incidentCenter,
    required double radiusMeters,
    required String? selectedIncidentId,
    required String incidentId,
    bool forceForIncident = false,
  }) {
    if (forceForIncident) return true;
    if (selectedIncidentId == incidentId) return true;
    if (zoom < minZoomForPatients) return false;
    final distM = _distance(cameraCenter, incidentCenter);
    return distM <= radiusMeters;
  }

  static String triageLocationIcon(String triageColor) {
    switch (triageColor) {
      case 'rojo':
        return AppIcons.unicoPacienteLocationRojo;
      case 'verde':
      case 'azul':
        return AppIcons.unicoPacienteLocationVerde;
      case 'negro':
        return AppIcons.unicoPacienteLocationNegro;
      case 'amarillo':
      case 'naranja':
      default:
        return AppIcons.unicoPacienteLocationAmarillo;
    }
  }
}
