import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';

class PatientDescriptionData {
  /* / Conjunto de lesiones actualmente seleccionadas como chips. */
  final Set<PatientInjuryType> selectedInjuries;

  /* / Texto libre de la descripción del paciente. */
  final String descriptionText;

  /* / Callback al presionar el "+" de un chip de lesión (agrega o quita de la selección). */
  final void Function(PatientInjuryType) onInjuryToggled;

  /* / Callback cuando cambia el texto de descripción libre. */
  final void Function(String) onDescriptionChanged;

  /* / Indica si la vista es de solo lectura. */
  final bool isReadOnly;

  const PatientDescriptionData({
    required this.selectedInjuries,
    required this.descriptionText,
    required this.onInjuryToggled,
    required this.onDescriptionChanged,
    this.isReadOnly = false,
  });
}
