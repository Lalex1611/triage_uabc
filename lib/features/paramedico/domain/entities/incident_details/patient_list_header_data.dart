import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';

// Datos necesarios para renderizar el encabezado de la lista de pacientes
class PatientListHeaderData {
  final int patientCount;
  final PatientSortOption sortOption;
  final void Function(PatientSortOption) onSortChanged;

  PatientListHeaderData({
    required this.patientCount,
    required this.sortOption,
    required this.onSortChanged,
  });
}
