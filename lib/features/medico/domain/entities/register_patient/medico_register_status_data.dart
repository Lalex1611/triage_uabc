import 'package:flutter/foundation.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';

@immutable
class MedicoRegisterStatusData {
  final MedicoPatientStatus currentStatus;
  final ValueChanged<MedicoPatientStatus> onStatusChanged;

  // / Si es false, la pill se muestra estática (sin flecha, sin abrir dropdown)
  final bool canEdit;

  const MedicoRegisterStatusData({
    required this.currentStatus,
    required this.onStatusChanged,
    this.canEdit = true,
  });
}
