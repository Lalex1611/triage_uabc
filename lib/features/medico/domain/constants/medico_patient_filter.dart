// Catálogo de filtros de pacientes para Home del médico (mockup 01: por color de triage)
enum MedicoPatientFilter {
  todos('Todos'),
  rojo('Rojo'),
  naranja('Naranja'),
  amarillo('Amarillo'),
  verde('Verde'),
  azul('Azul');

  final String label;
  const MedicoPatientFilter(this.label);
}
