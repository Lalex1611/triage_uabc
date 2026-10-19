/// Fila JSON devuelta por `get_patient_status_by_code` (PostgREST / RPC)
/// Espejo mínimo del contrato acordado con el backend (BACKEND_ARCHITECTURE)
class ConsultaRpcRow {
  ConsultaRpcRow({
    required this.patientStatusRaw,
    this.statusChangedAt,
    this.hospitalName,
    this.hospitalAddress,
    this.hospitalPhone,
  });

  final String? patientStatusRaw;
  final DateTime? statusChangedAt;
  final String? hospitalName;
  final String? hospitalAddress;
  final String? hospitalPhone;

  factory ConsultaRpcRow.fromJson(Map<String, dynamic> json) {
    final timestamp = json['status_changed_at'];
    return ConsultaRpcRow(
      patientStatusRaw: json['patient_status'] as String?,
      statusChangedAt: timestamp is String
          ? DateTime.tryParse(timestamp)
          : null,
      hospitalName: json['hospital_name'] as String?,
      hospitalAddress: json['hospital_address'] as String?,
      hospitalPhone: json['hospital_phone'] as String?,
    );
  }
}
