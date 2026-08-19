/// Extra opcional en `push(..., '/paramedico/incident/:id/register')` para mostrar
/// coordenadas al instante sin esperar a `getIncident`
class PatientRegistrationRouteSeed {
  const PatientRegistrationRouteSeed({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
