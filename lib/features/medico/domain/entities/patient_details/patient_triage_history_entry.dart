import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';

/// Entrada individual del historial de triage y cambios de estado de un paciente
class PatientTriageHistoryEntry {
  final String id;
  final String patientId;
  final MedicoTriageCategory? oldTriageColor;
  final MedicoTriageCategory newTriageColor;
  final String? oldStatus;
  final String newStatus;
  final String? actorRole;
  final List<String> changedFields;
  final DateTime changedAt;

  const PatientTriageHistoryEntry({
    required this.id,
    required this.patientId,
    this.oldTriageColor,
    required this.newTriageColor,
    this.oldStatus,
    required this.newStatus,
    this.actorRole,
    required this.changedFields,
    required this.changedAt,
  });

  /// Nombre del rol para mostrar en pantalla (Paramédico, Médico, etc)
  String get actorRoleLabel {
    final role = actorRole?.toLowerCase();
    if (role == 'paramedico') return 'Paramédico';
    if (role == 'medico') return 'Médico';
    if (role == 'consulta') return 'Consulta Externa';
    return 'Sistema';
  }
}
