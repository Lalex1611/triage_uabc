// Catálogo de opciones de ordenamiento para la lista de pacientes dentro de un incidente
enum PatientSortOption {
  recent('Más reciente', 'RECIENTES'),
  gravity('Mayor gravedad', 'GRAVEDAD'),
  name('Nombre', 'NOMBRE');

  final String title;
  final String shortLabel;

  const PatientSortOption(this.title, this.shortLabel);
}
