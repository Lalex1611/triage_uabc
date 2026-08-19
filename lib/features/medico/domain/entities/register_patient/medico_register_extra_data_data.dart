import 'package:flutter/foundation.dart';

@immutable
class MedicoRegisterExtraDataData {
  final String? allergies;
  final String? medications;
  final String? medicalHistory;
  final bool isReadOnly;

  final ValueChanged<String> onAllergiesChanged;
  final ValueChanged<String> onMedicationsChanged;
  final ValueChanged<String> onMedicalHistoryChanged;

  const MedicoRegisterExtraDataData({
    required this.onAllergiesChanged,
    required this.onMedicationsChanged,
    required this.onMedicalHistoryChanged,
    this.allergies,
    this.medications,
    this.medicalHistory,
    this.isReadOnly = false,
  });
}
