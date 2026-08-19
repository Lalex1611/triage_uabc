import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';

class PatientPersonalData {
  /* / Día de nacimiento (1-31). Null si no se ha ingresado. */
  final int? birthDay;

  /* / Mes de nacimiento (1-12). Null si no se ha ingresado. */
  final int? birthMonth;

  /* / Año de nacimiento. Null si no se ha ingresado. */
  final int? birthYear;

  /* / Género del paciente. Null si no se ha seleccionado. */
  final PatientGender? gender;

  /* / Tipo de sangre del paciente. Null si no se ha seleccionado. */
  final PatientBloodType? bloodType;

  /* / Número de contacto de emergencia. Null si no se ha ingresado. */
  final String? contactNumber;

  /* / Callback cuando cambia el día. */
  final void Function(String) onDayChanged;

  /* / Callback cuando cambia el mes. */
  final void Function(String) onMonthChanged;

  /* / Callback cuando cambia el año. */
  final void Function(String) onYearChanged;

  /* / Callback cuando cambia el género. */
  final void Function(PatientGender?) onGenderChanged;

  /* / Callback cuando cambia el tipo de sangre. */
  final void Function(PatientBloodType?) onBloodTypeChanged;

  /* / Callback cuando cambia el número de contacto. */
  final void Function(String) onContactNumberChanged;

  /* / Indica si la vista es de solo lectura. */
  final bool isReadOnly;

  const PatientPersonalData({
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onGenderChanged,
    required this.onBloodTypeChanged,
    required this.onContactNumberChanged,
    this.birthDay,
    this.birthMonth,
    this.birthYear,
    this.gender,
    this.bloodType,
    this.contactNumber,
    this.isReadOnly = false,
  });
}
