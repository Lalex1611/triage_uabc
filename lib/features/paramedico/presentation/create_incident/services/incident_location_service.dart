import 'package:geolocator/geolocator.dart';

/// Obtiene la posición GPS para registrar la ubicación de un incidente
class IncidentLocationService {
  IncidentLocationService._();

  /// Obtiene las coordenadas actuales si el GPS está activo y con permisos
  static Future<({double lat, double lng})?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
    return (lat: pos.latitude, lng: pos.longitude);
  }

  static String? errorMessageForNullResult() {
    return 'No se pudo obtener la ubicación. Activa el GPS y concede permiso a la app.';
  }
}
