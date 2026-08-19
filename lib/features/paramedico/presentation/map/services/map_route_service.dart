import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Servicio para calcular rutas de conducción usando OSRM
class MapRouteService {
  MapRouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LatLng>> fetchDrivingRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$fromLng,$fromLat;$toLng,$toLat'
      '?overview=full&geometries=geojson',
    );
    try {
      final res = await _client.get(url).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) return [];
      final geometry = (routes.first as Map<String, dynamic>)['geometry'];
      if (geometry is! Map<String, dynamic>) return [];
      final coords = geometry['coordinates'];
      if (coords is! List) return [];
      return coords
          .whereType<List>()
          .map((c) {
            if (c.length < 2) return null;
            return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
          })
          .whereType<LatLng>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
