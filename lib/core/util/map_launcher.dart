import 'package:url_launcher/url_launcher.dart';

/// Abre [latitude], [longitude] en la app de mapas (p. ej. Google Maps) o en el navegador
Future<bool> launchMapsExternal(double latitude, double longitude) async {
  final q = Uri.encodeComponent('$latitude,$longitude');
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Ruta en coche hasta el destino, ya en modo navegación. Sin origen, Google
/// Maps sale de la posición actual del usuario
Uri directionsUri(double latitude, double longitude) =>
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });

/// Abre [directionsUri] en Google Maps (o en el navegador si no está
/// instalado). Devuelve `false` si no se pudo abrir
Future<bool> launchDirectionsExternal(double latitude, double longitude) async {
  try {
    return await launchUrl(
      directionsUri(latitude, longitude),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
