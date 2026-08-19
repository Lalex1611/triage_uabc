import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';

/// Lectura y conversión de datos demográficos del paciente
class PatientDemographicsMapper {
  PatientDemographicsMapper._();

  static Set<PatientInjuryType> injuriesFromDemo(Map<String, dynamic> demo) {
    final raw = demo['injury_types'];
    if (raw is! List) return {};
    final out = <PatientInjuryType>{};
    for (final e in raw) {
      final s = e.toString();
      for (final t in PatientInjuryType.values) {
        if (t.name == s) out.add(t);
      }
    }
    return out;
  }

  static PatientGender? genderFromDemo(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final g in PatientGender.values) {
      if (g.name == raw) return g;
    }
    return null;
  }

  static PatientBloodType? bloodFromDemo(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final b in PatientBloodType.values) {
      if (b.name == raw) return b;
    }
    return null;
  }

  static List<String> photoPathsFromDemo(Map<String, dynamic> demo) {
    final raw = demo['photo_local_paths'];
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static (double, double)? coordsFromDemographics(Map<String, dynamic> demo) {
    final lat = demo['registration_lat'];
    final lng = demo['registration_lng'];
    if (lat is num && lng is num) {
      return (lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  static (double lat, double lng) detailMapCoords({
    required ParamedicoPatientDetail detail,
    ParamedicoIncidentSummary? incident,
    HospitalRow? assignedHospital,
  }) {
    if (detail.latitude != null && detail.longitude != null) {
      return (detail.latitude!, detail.longitude!);
    }
    final demoCoords = coordsFromDemographics(detail.demographics);
    if (demoCoords != null) return demoCoords;
    if (detail.status == 'trasladando' &&
        assignedHospital?.latitude != null &&
        assignedHospital?.longitude != null) {
      return (assignedHospital!.latitude!, assignedHospital.longitude!);
    }
    if (incident?.latitude != null && incident?.longitude != null) {
      return (incident!.latitude!, incident.longitude!);
    }
    return (32.5027, -117.00371);
  }

  static bool hasStoredPatientLocation(ParamedicoPatientDetail detail) =>
      (detail.latitude != null && detail.longitude != null) ||
      coordsFromDemographics(detail.demographics) != null;

  static bool canShowMap({
    required ParamedicoPatientDetail detail,
    ParamedicoIncidentSummary? incident,
    HospitalRow? assignedHospital,
  }) {
    if (hasStoredPatientLocation(detail)) return true;
    if (detail.status == 'trasladando' &&
        assignedHospital?.latitude != null &&
        assignedHospital?.longitude != null) {
      return true;
    }
    if (incident?.latitude != null && incident?.longitude != null) return true;
    return false;
  }

  static String gpsLabel({
    required ParamedicoPatientDetail detail,
    ParamedicoIncidentSummary? incident,
    HospitalRow? assignedHospital,
  }) {
    if (detail.latitude != null && detail.longitude != null) {
      return '${detail.latitude!.toStringAsFixed(5)}, ${detail.longitude!.toStringAsFixed(5)}';
    }
    final demoCoords = coordsFromDemographics(detail.demographics);
    if (demoCoords != null) {
      return '${demoCoords.$1.toStringAsFixed(5)}, ${demoCoords.$2.toStringAsFixed(5)}';
    }
    if (detail.status == 'trasladando' &&
        assignedHospital?.latitude != null &&
        assignedHospital?.longitude != null) {
      return '${assignedHospital!.latitude!.toStringAsFixed(5)}, ${assignedHospital!.longitude!.toStringAsFixed(5)}';
    }
    if (incident?.latitude != null && incident?.longitude != null) {
      return '${incident!.latitude!.toStringAsFixed(5)}, ${incident!.longitude.toStringAsFixed(5)}';
    }
    return '—';
  }

  static String relativeCreated(DateTime? at) {
    if (at == null) return '—';
    final diff = DateTime.now().difference(at.toLocal());
    if (diff.inMinutes < 1) return 'unos momentos';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutos';
    if (diff.inHours < 24) return '${diff.inHours} horas';
    return '${diff.inDays} días';
  }
}
