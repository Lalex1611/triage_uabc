import 'package:url_launcher/url_launcher.dart';

/// Abre [latitude], [longitude] en la app de mapas (p. ej. Google Maps) o en el navegador
Future<bool> launchMapsExternal(double latitude, double longitude) async {
  final q = Uri.encodeComponent('$latitude,$longitude');
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
