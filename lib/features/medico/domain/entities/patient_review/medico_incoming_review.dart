import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/// Todo lo que el médico necesita para decidir si recibe a un paciente que
/// viene en camino (mockup 02). Se arma desde `patients` con su incidente,
/// unidad, paramédico y fotos.
class MedicoIncomingReview {
  final String patientId;
  final String displayName;
  final TriageCategory triage;
  final int? ageYears;

  /// "masculino" / "femenino"
  final String? gender;

  // De dónde viene
  final String? incidentId;
  final String? incidentTitle;
  final String? emergencyTypeLabel;
  final String? paramedicName;
  final String? unitCode;
  final DateTime? classifiedAt;
  final DateTime? estimatedArrivalAt;
  final String? regulationFolio;

  /// Enlaces temporales (firmados) de las fotos del incidente en Storage
  final List<String> photoUrls;

  // Estado reportado por el paramédico
  final String? reportedDescription;
  final List<String> injuryLabels;
  final String? startTriageModeLabel;

  // Datos administrativos (null = no se registró)
  final bool? hasInsurance;

  /// Institución del seguro (IMSS, ISSSTE, ...), si se capturó
  final String? insuranceInstitution;
  final String? bloodTypeLabel;
  final String? contactPhone;

  const MedicoIncomingReview({
    required this.patientId,
    required this.displayName,
    required this.triage,
    this.ageYears,
    this.gender,
    this.incidentId,
    this.incidentTitle,
    this.emergencyTypeLabel,
    this.paramedicName,
    this.unitCode,
    this.classifiedAt,
    this.estimatedArrivalAt,
    this.regulationFolio,
    this.photoUrls = const [],
    this.reportedDescription,
    this.injuryLabels = const [],
    this.startTriageModeLabel,
    this.hasInsurance,
    this.insuranceInstitution,
    this.bloodTypeLabel,
    this.contactPhone,
  });

  bool get hasReportedState =>
      reportedDescription != null ||
      injuryLabels.isNotEmpty ||
      startTriageModeLabel != null;

  /// "IMSS", "Sí", "No" o null si no se sabe
  String? get insuranceLabel {
    if (hasInsurance == null) return null;
    if (!hasInsurance!) return 'No';
    return insuranceInstitution ?? 'Sí';
  }

  bool get hasAdministrativeData =>
      hasInsurance != null || bloodTypeLabel != null || contactPhone != null;

  /// Arma la revisión desde la fila de `patients` con sus relaciones embebidas
  /// (`incidents`, `ambulancias_unidades`, `profiles`).
  factory MedicoIncomingReview.fromRow(
    Map<String, dynamic> row, {
    List<String> photoUrls = const [],
    DateTime? classifiedAt,
    DateTime? now,
  }) {
    final demo = row['demographics'] is Map
        ? Map<String, dynamic>.from(row['demographics'] as Map)
        : <String, dynamic>{};
    final incident = row['incidents'] is Map
        ? Map<String, dynamic>.from(row['incidents'] as Map)
        : null;
    final unit = row['ambulancias_unidades'] is Map
        ? Map<String, dynamic>.from(row['ambulancias_unidades'] as Map)
        : null;
    final creator = row['creator'] is Map
        ? Map<String, dynamic>.from(row['creator'] as Map)
        : null;

    final triageRaw = row['triage_color'] as String? ?? 'amarillo';
    final triage = TriageCategory.values.firstWhere(
      (c) => c.name == triageRaw,
      orElse: () => TriageCategory.amarillo,
    );

    final name =
        _text(row['display_name']) ??
        _text(row['regulation_folio']) ??
        'Paciente sin identificar';

    final emergencyType = _text(incident?['emergency_type']);

    return MedicoIncomingReview(
      patientId: row['id'] as String,
      displayName: name,
      triage: triage,
      ageYears: ageFrom(demo, now ?? DateTime.now()),
      gender: _text(demo['gender']),
      incidentId: _text(row['incident_id']),
      incidentTitle: _text(incident?['generated_title']),
      emergencyTypeLabel: emergencyType == null
          ? null
          : EmergencyCatalog.nameFor(emergencyType),
      paramedicName: _text(creator?['full_name']),
      unitCode: _text(unit?['numero_economico']),
      classifiedAt:
          classifiedAt ??
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal(),
      estimatedArrivalAt: DateTime.tryParse(
        row['estimated_arrival_at'] as String? ?? '',
      )?.toLocal(),
      regulationFolio: _text(row['regulation_folio']),
      photoUrls: photoUrls,
      reportedDescription:
          _text(demo['description']) ?? _text(row['descriptive_notes']),
      injuryLabels: _injuries(demo['injury_types']),
      startTriageModeLabel: demo['registered_from_start'] == true
          ? _startMode(demo['start_triage_mode'])
          : null,
      hasInsurance: insuranceFrom(demo),
      insuranceInstitution: _text(demo['insurance_institution']),
      bloodTypeLabel: _bloodType(demo['blood_type']),
      contactPhone: _text(demo['emergency_contact']),
    );
  }

  /// Edad cumplida a partir de birth_year/month/day (mes y día opcionales)
  static int? ageFrom(Map<String, dynamic> demo, DateTime now) {
    final y = (demo['birth_year'] as num?)?.toInt();
    if (y == null || y < 1900 || y > now.year) return null;
    final m = (demo['birth_month'] as num?)?.toInt();
    final d = (demo['birth_day'] as num?)?.toInt();
    var age = now.year - y;
    if (m != null) {
      final birthdayPassed =
          now.month > m || (now.month == m && (d == null || now.day >= d));
      if (!birthdayPassed) age--;
    }
    return age < 0 ? null : age;
  }

  /// El médico guarda `seguro_medico` ("si"/"no") y el paramédico, al enviar
  /// el traslado, `has_medical_insurance` (bool). Se aceptan ambos.
  static bool? insuranceFrom(Map<String, dynamic> demo) {
    for (final key in const [
      'seguro_medico',
      'has_medical_insurance',
      'has_insurance',
      'insurance',
    ]) {
      final v = demo[key];
      if (v is bool) return v;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'si' || s == 'sí' || s == 'true') return true;
        if (s == 'no' || s == 'false') return false;
      }
    }
    return null;
  }

  static String? _text(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _injuries(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        for (final t in PatientInjuryType.values)
          if (t.name == e.toString()) t.label,
    ];
  }

  static String? _startMode(Object? raw) {
    for (final m in StartTriageTabOption.values) {
      if (m.name == raw) return m.label;
    }
    return 'START';
  }

  static String? _bloodType(Object? raw) {
    for (final b in PatientBloodType.values) {
      if (b.name == raw) return b.label;
    }
    return null;
  }
}
