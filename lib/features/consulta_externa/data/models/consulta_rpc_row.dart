/// Fila JSON devuelta por `get_patient_status_by_code` (PostgREST / RPC)
/// Espejo mínimo del contrato acordado con el backend (BACKEND_ARCHITECTURE)
class ConsultaRpcRow {
  ConsultaRpcRow({
    required this.patientStatusRaw,
    this.hospitalName,
    this.hospitalAddress,
    this.hospitalPhone,
  });

  final String? patientStatusRaw;
  final String? hospitalName;
  final String? hospitalAddress;
  final String? hospitalPhone;

  factory ConsultaRpcRow.fromJson(Map<String, dynamic> json) {
    return ConsultaRpcRow(
      patientStatusRaw: json['patient_status'] as String?,
      hospitalName: json['hospital_name'] as String?,
      hospitalAddress: json['hospital_address'] as String?,
      hospitalPhone: json['hospital_phone'] as String?,
    );
  }
}
