import 'package:sistema_triage/core/geo/nominatim_reverse_geocode.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_title_formatter.dart';

/// Nombre de paciente: prefijo correlativo + sufijo de fecha/hora/lugar (mismo criterio que incidente)
class PatientDisplayNameFormatter {
  PatientDisplayNameFormatter._();

  /// Si [customName] no está vacío, se usa tal cual; si no, genera `Paciente Numero N - …`
  static Future<String> resolveDisplayName({
    required String? customName,
    required int patientNumber,
    required DateTime atLocal,
    required double lat,
    required double lng,
  }) async {
    final t = customName?.trim();
    if (t != null && t.isNotEmpty) return t;

    final place = await NominatimReverseGeocode.shortPlaceLabel(lat, lng);
    final key = (place != null && place.isNotEmpty)
        ? place
        : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

    return formatAuto(
      patientNumber: patientNumber,
      atLocal: atLocal,
      locationKey: key,
    );
  }

  /// Ej. `Paciente Numero 3 - 18-marzo-2026 14:32-Boulevard 2000`
  static String formatAuto({
    required int patientNumber,
    required DateTime atLocal,
    required String locationKey,
  }) {
    final suffix = IncidentTitleFormatter.formatAuto(
      atLocal: atLocal,
      locationKey: locationKey,
    );
    return 'Paciente Numero $patientNumber - $suffix';
  }
}
