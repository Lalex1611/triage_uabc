// Catálogo de opciones para las pestañas de la vista de detalles
enum IncidentTabType {
  lista('Lista', 95),
  mapa('Mapa', 96),
  fotos('Fotos', 95),
  estadisticas('Estadísticas', 96);

  final String label;
  final double width;
  const IncidentTabType(this.label, this.width);
}

class IncidentTabSelectorData {
  final IncidentTabType activeTab;
  final Function(IncidentTabType) onTabChanged;
  final List<IncidentTabType> availableTabs;

  IncidentTabSelectorData({
    required this.activeTab,
    required this.onTabChanged,
    required this.availableTabs,
  });
}
