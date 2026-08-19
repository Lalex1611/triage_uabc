import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';

class PatientStatusData {
  final String creatorName;
  final String timeElapsed;
  final PatientStatus currentStatus;
  final bool canEdit;
  final Function(PatientStatus) onStatusChanged;

  const PatientStatusData({
    required this.creatorName,
    required this.timeElapsed,
    required this.currentStatus,
    required this.canEdit,
    required this.onStatusChanged,
  });
}
