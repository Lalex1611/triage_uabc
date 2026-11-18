/// Capacidad de urgencias del hospital (mockup 13). Null = sin capturar.
class MedicoHospitalCapacity {
  final int? shockBedsFree;
  final int? shockBedsTotal;
  final int? observationBedsFree;
  final int? observationBedsTotal;
  final bool? acceptingRedPatients;
  final bool? operatingRoomAvailable;
  final DateTime? updatedAt;

  const MedicoHospitalCapacity({
    this.shockBedsFree,
    this.shockBedsTotal,
    this.observationBedsFree,
    this.observationBedsTotal,
    this.acceptingRedPatients,
    this.operatingRoomAvailable,
    this.updatedAt,
  });

  factory MedicoHospitalCapacity.fromJson(Map<String, dynamic> j) {
    int? i(String k) => (j[k] as num?)?.toInt();
    return MedicoHospitalCapacity(
      shockBedsFree: i('shock_beds_free'),
      shockBedsTotal: i('shock_beds_total'),
      observationBedsFree: i('observation_beds_free'),
      observationBedsTotal: i('observation_beds_total'),
      acceptingRedPatients: j['accepting_red_patients'] as bool?,
      operatingRoomAvailable: j['operating_room_available'] as bool?,
      updatedAt: DateTime.tryParse(
        j['capacity_updated_at'] as String? ?? '',
      )?.toLocal(),
    );
  }
}

/// Conteos de la guardia de hoy (desde la medianoche de Tijuana)
class MedicoShiftSummary {
  final int received;
  final int rejected;
  final int discharged;
  final int inRoom;

  const MedicoShiftSummary({
    required this.received,
    required this.rejected,
    required this.discharged,
    required this.inRoom,
  });

  factory MedicoShiftSummary.fromJson(Map<String, dynamic> j) {
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    return MedicoShiftSummary(
      received: i('received'),
      rejected: i('rejected'),
      discharged: i('discharged'),
      inRoom: i('in_room'),
    );
  }
}

/// Lo que muestra el perfil del médico: hospital, capacidad y guardia
class MedicoProfileSummary {
  final String hospitalName;

  /// "Urgencias" / "Consulta regular" (o null si el hospital no lo indica)
  final String? hospitalAreaLabel;
  final MedicoHospitalCapacity capacity;
  final MedicoShiftSummary shift;

  const MedicoProfileSummary({
    required this.hospitalName,
    required this.hospitalAreaLabel,
    required this.capacity,
    required this.shift,
  });

  /// "Urgencias" / "Consulta regular" según `hospitals.center_kind`
  static String? areaLabelOf(String? centerKind) => switch (centerKind) {
    'urgencias' => 'Urgencias',
    'consulta_regular' => 'Consulta regular',
    _ => null,
  };

  /// "Hospital General de Tijuana · Urgencias" (encabezados del médico)
  static String hospitalLabel(String name, String? areaLabel) =>
      [name, ?areaLabel].join(' · ');

  factory MedicoProfileSummary.fromJson(Map<String, dynamic> j) {
    final h = Map<String, dynamic>.from(j['hospital'] as Map? ?? const {});
    final s = Map<String, dynamic>.from(j['shift'] as Map? ?? const {});
    final area = areaLabelOf(h['center_kind'] as String?);
    return MedicoProfileSummary(
      hospitalName: (h['name'] as String?)?.trim().isNotEmpty == true
          ? h['name'] as String
          : 'Hospital sin nombre',
      hospitalAreaLabel: area,
      capacity: MedicoHospitalCapacity.fromJson(h),
      shift: MedicoShiftSummary.fromJson(s),
    );
  }
}
