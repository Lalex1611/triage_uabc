/// Paciente georreferenciado para el mapa interactivo
class MapPatientPin {
  const MapPatientPin({
    required this.id,
    required this.incidentId,
    required this.latitude,
    required this.longitude,
    required this.triageColor,
  });

  final String id;
  final String incidentId;
  final double latitude;
  final double longitude;
  final String triageColor;
}
