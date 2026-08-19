import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';

// Datos necesarios para renderizar la barra de filtros de triage de pacientes
class PatientTriageFiltersData {
  final PatientTriageFilter activeFilter;
  final Function(PatientTriageFilter) onFilterChanged;

  PatientTriageFiltersData({
    required this.activeFilter,
    required this.onFilterChanged,
  });
}
