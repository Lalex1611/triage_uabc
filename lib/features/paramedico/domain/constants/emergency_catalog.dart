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
}
