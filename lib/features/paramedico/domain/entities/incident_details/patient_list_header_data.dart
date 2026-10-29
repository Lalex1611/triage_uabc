import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';

// Datos necesarios para renderizar el encabezado de la lista de pacientes
class PatientListHeaderData {
  final int patientCount;
  final PatientSortOption? sortOption;
  final void Function(PatientSortOption)? onSortChanged;

  const PatientListHeaderData({
    required this.patientCount,
    this.sortOption,
    this.onSortChanged,
  });
}
