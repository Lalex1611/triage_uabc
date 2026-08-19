// Catálogo de filtros de pacientes para Home del médico
enum MedicoPatientFilter {
  enCamino('En camino'),
  recibidos('Recibidos'),
  independientes('Independientes'),
  triageHospitalario('TRIAGE - HOSPITALARIO');

  final String label;
  const MedicoPatientFilter(this.label);
}
