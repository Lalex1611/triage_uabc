enum MedicoQueueFilter {
  enCamino('En camino'),
  recibidos('Recibidos'),
  independientes('Independientes'),
  triageHospitalario('TRIAGE - HOSPITALARIO');

  final String label;

  const MedicoQueueFilter(this.label);
}
