import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';

/// Formateo de incidentes/pacientes para etiquetas de UI (sin widgets)
class IncidentPresentationFormatters {
  IncidentPresentationFormatters._();

  static const _defaultLat = 32.5027;
  static const _defaultLng = -117.00371;
  static String shortIncidentId(String id) {
    final short = id.length >= 6
        ? id.substring(0, 6).toUpperCase()
        : id.toUpperCase();
    return 'INC-$short';
  }

  static String shortPatientId(String id) {
    final short = id.length >= 6
        ? id.substring(0, 6).toUpperCase()
        : id.toUpperCase();
    return 'PAC-$short';
  }

  static bool hasIncidentLocation(ParamedicoIncidentSummary inc) =>
      inc.latitude != null && inc.longitude != null;

  static (double lat, double lng) incidentMapCoords(
    ParamedicoIncidentSummary inc,
  ) {
    if (hasIncidentLocation(inc)) {
      return (inc.latitude!, inc.longitude!);
    }
    return (_defaultLat, _defaultLng);
  }

  static String incidentGpsLabel(ParamedicoIncidentSummary inc) {
    if (!hasIncidentLocation(inc)) return '—';
    return '${inc.latitude!.toStringAsFixed(5)}, ${inc.longitude!.toStringAsFixed(5)}';
  }

  static String formatTime(DateTime? d) {
    if (d == null) return '—';
    final x = d.toLocal();
    final hh = x.hour.toString().padLeft(2, '0');
    final mi = x.minute.toString().padLeft(2, '0');
    return '$hh:$mi';
  }

  static String relativeCreated(DateTime? at) {
    if (at == null) return '—';
    final diff = DateTime.now().difference(at.toLocal());
    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    return 'Hace ${diff.inDays} días';
  }
}
