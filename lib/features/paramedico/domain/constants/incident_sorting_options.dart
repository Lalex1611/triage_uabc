enum IncidentSortOption {
  recent('Más reciente', 'RECIENTES'),
  gravity('Mayor gravedad', 'GRAVEDAD'),
  victims('Total de víctimas', 'VÍCTIMAS');

  final String title;
  final String shortLabel;

  const IncidentSortOption(this.title, this.shortLabel);
}
