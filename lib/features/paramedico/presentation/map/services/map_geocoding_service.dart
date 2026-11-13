import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Busca una dirección con Nominatim (geocodificador de OpenStreetMap)
///
/// Su política de uso pide identificar la app y no más de una consulta por
/// segundo: por eso se busca al enviar, no con cada letra.
class MapGeocodingService {
  MapGeocodingService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Primer resultado para [query], priorizando la zona de [near]; nulo si no
  /// hay resultados o falla la red
  Future<LatLng?> search(String query, {LatLng? near}) async {
    final params = {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'mx',
      'accept-language': 'es',
      // Caja de ~0.4° alrededor de [near]: ordena primero lo cercano sin
      // descartar lo de fuera
      if (near != null)
        'viewbox': [
          near.longitude - 0.2,
          near.latitude + 0.2,
          near.longitude + 0.2,
          near.latitude - 0.2,
        ].join(','),
    };
    final url = Uri.https('nominatim.openstreetmap.org', '/search', params);
    try {
      final res = await _client
          .get(url, headers: const {'User-Agent': 'sistema_triage'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! List || body.isEmpty) return null;
      final first = body.first as Map<String, dynamic>;
      final lat = double.tryParse('${first['lat']}');
      final lon = double.tryParse('${first['lon']}');
      if (lat == null || lon == null) return null;
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }
}
