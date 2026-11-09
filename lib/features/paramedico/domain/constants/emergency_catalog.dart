import 'package:sistema_triage/features/paramedico/domain/entities/create_incident/emergency_type.dart';

/// Catálogo alineado con el enum PostgreSQL `public.emergency_type`
/// Única fuente para dropdowns de tipo de emergencia 
class EmergencyCatalog {
  static const List<EmergencyType> postgresIncidentTypes = [
    EmergencyType(id: 'accidente_vehicular', name: 'Accidente vehicular'),
    EmergencyType(id: 'derrumbe', name: 'Derrumbe'),
    EmergencyType(id: 'incidente_masivo', name: 'Incidente masivo'),
    EmergencyType(id: 'otro', name: 'Otro'),
  ];

  /// Alias histórico usado en sandboxes (`create_incident_visual_test`, etc.)
  static const List<EmergencyType> standardTypes = postgresIncidentTypes;

  static String get defaultTypeId => postgresIncidentTypes.first.id;

  /// Nombre visible de un tipo; los que no están en el catálogo (p. ej.
  /// `violencia`, que existe en el enum) se muestran a partir de su clave
  static String nameFor(String id) {
    for (final type in postgresIncidentTypes) {
      if (type.id == id) return type.name;
    }
    final text = id.replaceAll('_', ' ').trim();
    return text.isEmpty ? 'Otro' : text[0].toUpperCase() + text.substring(1);
  }
}
