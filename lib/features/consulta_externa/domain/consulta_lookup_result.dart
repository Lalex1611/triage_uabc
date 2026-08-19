import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';

/// resultado de [get_patient_status_by_code] RPC par la familia / consulta externa
class ConsultaLookupResult {
  final ConsultaStatus status;
  final String? hospitalName;
  final String? hospitalAddress;
  final String? hospitalPhone;

  const ConsultaLookupResult({
    required this.status,
    this.hospitalName,
    this.hospitalAddress,
    this.hospitalPhone,
  });

  bool get hasHospitalAssignment =>
      hospitalName != null && hospitalName!.trim().isNotEmpty;
}
