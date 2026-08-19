import 'dart:convert';

import 'package:http/http.dart' as http;

/// Nominatim (OSM): nombre corto de vía para títulos de incidente
/// Política de uso: https://operations.osmfoundation.org/policies/nominatim/
class NominatimReverseGeocode {
  NominatimReverseGeocode._();

  static const _ua = 'SistemaTriage/1.0 (paramedico-incident-title; contacto institucional)';

  /// Devuelve algo legible (calle + número o barrio) o `null` si falla
  static Future<String?> shortPlaceLabel(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'json',
      'addressdetails': '1',
      'zoom': '18',
    });
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': _ua, 'Accept-Language': 'es'},
      );
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>?;
      if (j == null) return null;
      final addr = j['address'];
      if (addr is! Map<String, dynamic>) return null;
      final road = addr['road'] as String?;
      final house = addr['house_number'] as String?;
      final suburb = addr['suburb'] as String? ?? addr['neighbourhood'] as String?;
      if (road != null && road.isNotEmpty) {
        final h = house != null && house.isNotEmpty ? ' $house' : '';
        return '$road$h'.trim();
      }
      if (suburb != null && suburb.isNotEmpty) return suburb;
      final city = addr['city'] as String? ?? addr['town'] as String?;
      if (city != null && city.isNotEmpty) return city;
      return null;
    } catch (_) {
      return null;
    }
  }
}
