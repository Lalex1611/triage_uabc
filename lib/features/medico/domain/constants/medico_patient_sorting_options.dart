// Catálogo de opciones de ordenamiento para la lista de pacientes en Home del médico
enum MedicoPatientSortOption {
  recent('Más reciente', 'RECIENTES'),
  gravity('Mayor gravedad', 'GRAVEDAD'),
  name('Nombre', 'NOMBRE');

  final String title;
  final String shortLabel;

  const MedicoPatientSortOption(this.title, this.shortLabel);
}
