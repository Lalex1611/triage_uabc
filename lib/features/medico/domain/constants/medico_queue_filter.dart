// Filtros de la Sala hospitalaria (mockup 05)
enum MedicoQueueFilter {
  todos('Todos'),
  enEspera('En espera'),
  recibidos('Recibidos'),
  dadosDeAlta('Dados de alta');

  final String label;

  const MedicoQueueFilter(this.label);
}
