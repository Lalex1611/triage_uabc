import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';

class DetailsMapData {
  final PatientMapData mapData;
  final PatientStatus currentStatus;
  final String? assignedHospital;
  final String? headingToText;

  const DetailsMapData({
    required this.mapData,
    required this.currentStatus,
    this.assignedHospital,
    this.headingToText,
  });
}
