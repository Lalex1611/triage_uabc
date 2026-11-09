// Catálogo de opciones para las pestañas de la vista de detalles
enum IncidentTabType {
  lista('Pacientes'),
  mapa('Mapa'),
  fotos('Detalles'),
  estadisticas('Resumen');

  final String label;
  const IncidentTabType(this.label);
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
