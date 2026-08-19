import 'package:latlong2/latlong.dart';

/// Coordenadas y límites de la región operativa
abstract final class MapOperationalRegion {
  /// Centro predeterminado del mapa (zona urbana)
  static const LatLng overviewCenter = LatLng(32.47, -116.95);

  /// Nivel de zoom inicial para la vista general
  static const double overviewZoom = 10.4;

  static const double _minLat = 32.22;
  static const double _maxLat = 32.62;
  static const double _minLng = -117.30;
  static const double _maxLng = -116.52;

  static bool contains(double lat, double lng) =>
      lat >= _minLat && lat <= _maxLat && lng >= _minLng && lng <= _maxLng;
}
