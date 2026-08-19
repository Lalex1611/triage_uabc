import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Funciones de ayuda para la vista y rotación del mapa durante la navegación
class MapNavigationHelpers {
  MapNavigationHelpers._();

  static const double navigationZoom = 17.5;

  /// Ajuste de pantalla para mantener al usuario centrado hacia abajo
  static const Offset userScreenOffset = Offset(0, 110);

  /// Orientación en grados según la posición o movimiento actual
  static double resolveHeading({
    required Position position,
    LatLng? previous,
    required LatLng current,
    double? lastHeading,
  }) {
    final h = position.heading;
    if (h >= 0 && h <= 360) return h;

    if (previous != null) {
      const dist = Distance();
      final meters = dist(previous, current);
      if (meters >= 4) {
        return dist.bearing(previous, current);
      }
    }
    return lastHeading ?? 0;
  }

  /// Calcula la rotación del mapa para alinear con la dirección de avance
  static double mapRotationForHeading(double headingDegrees) {
    var r = -headingDegrees % 360;
    if (r < 0) r += 360;
    return r;
  }

  /// Ajusta el trazado de la ruta para mostrar solo la distancia restante
  static List<LatLng> trimRouteAhead({
    required List<LatLng> route,
    required LatLng user,
  }) {
    if (route.length < 2) return route;

    var closestIdx = 0;
    var closestDist = double.infinity;
    const dist = Distance();
    for (var i = 0; i < route.length; i++) {
      final d = dist(user, route[i]);
      if (d < closestDist) {
        closestDist = d;
        closestIdx = i;
      }
    }

    final ahead = route.sublist(closestIdx);
    if (ahead.isEmpty) return route;
    if (ahead.length == 1) return [user, ahead.first];
    return [user, ...ahead.skip(1)];
  }
}
