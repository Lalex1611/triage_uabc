import 'package:sistema_triage/features/medico/domain/constants/medico_patient_filter.dart';

// Datos del filtro de triage para la lista de pacientes en Home del médico
class MedicoTriageFiltersData {
  final MedicoPatientFilter activeFilter;
  final void Function(MedicoPatientFilter) onFilterChanged;

  const MedicoTriageFiltersData({
    required this.activeFilter,
    required this.onFilterChanged,
  });
}
