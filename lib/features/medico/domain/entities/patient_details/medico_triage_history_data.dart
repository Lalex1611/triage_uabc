import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';

/// Datos que recibe la lista de historial de triage y estado del paciente
class MedicoTriageHistoryData {
  final List<PatientTriageHistoryEntry> entries;
  final bool isLoading;

  const MedicoTriageHistoryData({
    required this.entries,
    this.isLoading = false,
  });
}
