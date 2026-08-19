import 'package:sistema_triage/core/geo/nominatim_reverse_geocode.dart';

/// Título genérico: `d-mes-año HH:mm-nombreClaveUbicación` (ej. 18-marzo-2026 14:32-Blvrd. 2000)
class IncidentTitleFormatter {
  IncidentTitleFormatter._();

  static const _meses = <int, String>{
    1: 'enero',
    2: 'febrero',
    3: 'marzo',
    4: 'abril',
    5: 'mayo',
    6: 'junio',
    7: 'julio',
    8: 'agosto',
    9: 'septiembre',
    10: 'octubre',
    11: 'noviembre',
    12: 'diciembre',
  };

  /// Si [customTitle] no está vacío, se usa tal cual; si no, genera con fecha y ubicación
  static Future<String> resolveTitle({
    required String? customTitle,
    required DateTime atLocal,
    required double lat,
    required double lng,
  }) async {
    final t = customTitle?.trim();
    if (t != null && t.isNotEmpty) return t;

    final place = await NominatimReverseGeocode.shortPlaceLabel(lat, lng);
    final key = (place != null && place.isNotEmpty)
        ? place
        : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

    return formatAuto(atLocal: atLocal, locationKey: key);
  }

  static String formatAuto({
    required DateTime atLocal,
    required String locationKey,
  }) {
    final d = atLocal;
    final mes = _meses[d.month] ?? d.month.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}-$mes-${d.year} $hh:$mm-$locationKey';
  }
}
