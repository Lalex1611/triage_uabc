// Catálogo de opciones de filtro por triage para la lista de pacientes
enum PatientTriageFilter {
  todos('Todos'),
  rojo('Rojo'),
  amarillo('Amarillo'),
  verde('Verde'),
  negro('Negro');

  final String label;
  const PatientTriageFilter(this.label);
}
