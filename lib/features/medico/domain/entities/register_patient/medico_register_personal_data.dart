import 'package:flutter/foundation.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_option.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';

@immutable
class MedicoRegisterPersonalData {
  final String? birthDay;
  final String? birthMonth;
  final String? birthYear;
  final MedicoPatientGender? gender;
  final String? contactNumber;
  final MedicoInsuranceOption? insurance;

  // / Si es true, los campos se muestran como solo lectura (no editables) y
  final bool isReadOnly;

  /* / Si se provee, se muestra un lápiz a la derecha de la sección. */
  final VoidCallback? onEditTap;

  final ValueChanged<String> onDayChanged;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<MedicoPatientGender?> onGenderChanged;
  final ValueChanged<String> onContactNumberChanged;
  final ValueChanged<MedicoInsuranceOption?> onInsuranceChanged;

  const MedicoRegisterPersonalData({
    required this.birthDay,
    required this.birthMonth,
    required this.birthYear,
    required this.gender,
    required this.contactNumber,
    required this.insurance,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onGenderChanged,
    required this.onContactNumberChanged,
    required this.onInsuranceChanged,
    this.isReadOnly = false,
    this.onEditTap,
  });
}
