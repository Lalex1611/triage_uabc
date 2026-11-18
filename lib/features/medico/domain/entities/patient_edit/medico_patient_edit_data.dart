import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_walk_in_insurance.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';

/// Datos que el médico puede editar de un paciente en sala: identificación,
/// seguro, datos adicionales y signos vitales. Se lee y se escribe sobre
/// `patients.display_name`, `demographics` y `vital_signs`.
class MedicoPatientEditData {
  final String displayName;
  final int? birthDay;
  final int? birthMonth;
  final int? birthYear;
  final MedicoPatientGender? gender;
  final PatientBloodType? bloodType;
  final String phone;

  /// null = no se sabe / no se ha capturado
  final MedicoWalkInInsurance? insurance;
  final String institution;

  final String allergies;
  final String medications;
  final String medicalHistory;

  /// Claves canónicas: [vitalKeys]
  final Map<String, String> vitals;

  const MedicoPatientEditData({
    required this.displayName,
    this.birthDay,
    this.birthMonth,
    this.birthYear,
    this.gender,
    this.bloodType,
    this.phone = '',
    this.insurance,
    this.institution = '',
    this.allergies = '',
    this.medications = '',
    this.medicalHistory = '',
    this.vitals = const {},
  });

  /// Claves canónicas de signos vitales y sus alias antiguos (seed / otras
  /// pantallas) que se leen y se limpian al guardar
  static const vitalKeys = <String, List<String>>{
    'systolic_pressure': ['ta_sist', 'systolic', 'tas'],
    'diastolic_pressure': ['ta_diast', 'diastolic', 'tad'],
    'heart_rate': ['fc'],
    'respiratory_rate': ['fr'],
    'temperature': ['temp'],
    'oxygen_saturation': ['spo2'],
    'glucose': [],
  };

  factory MedicoPatientEditData.fromRecord({
    required String displayName,
    required Map<String, dynamic> demographics,
    required Map<String, dynamic> vitalSigns,
  }) {
    final d = demographics;
    String text(String k) => (d[k] as String?)?.trim() ?? '';
    int? number(String k) => (d[k] as num?)?.toInt();

    final hasInsurance = MedicoIncomingReview.insuranceFrom(d);
    final vitals = <String, String>{};
    vitalKeys.forEach((key, aliases) {
      for (final k in [key, ...aliases]) {
        final v = vitalSigns[k] ?? d[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          vitals[key] = v.toString().trim();
          break;
        }
      }
    });

    MedicoPatientGender? gender;
    for (final g in MedicoPatientGender.values) {
      if (g.name == d['gender']) gender = g;
    }
    PatientBloodType? blood;
    for (final b in PatientBloodType.values) {
      if (b.name == d['blood_type']) blood = b;
    }

    return MedicoPatientEditData(
      displayName: displayName,
      birthDay: number('birth_day'),
      birthMonth: number('birth_month'),
      birthYear: number('birth_year'),
      gender: gender,
      bloodType: blood,
      phone: text('emergency_contact'),
      insurance: hasInsurance == null
          ? null
          : (hasInsurance
                ? MedicoWalkInInsurance.si
                : MedicoWalkInInsurance.no),
      institution: text('insurance_institution'),
      allergies: text('allergies'),
      medications: text('medications'),
      medicalHistory: text('medical_history'),
      vitals: vitals,
    );
  }

  /// Copia de [demographics] con estos datos aplicados (conserva lo demás:
  /// fotos, lesiones, descripción del paramédico, etc.)
  Map<String, dynamic> applyToDemographics(Map<String, dynamic> demographics) {
    final out = Map<String, dynamic>.from(demographics);
    void setOrRemove(String k, Object? v) {
      if (v == null || (v is String && v.trim().isEmpty)) {
        out.remove(k);
      } else {
        out[k] = v is String ? v.trim() : v;
      }
    }

    setOrRemove('birth_day', birthDay);
    setOrRemove('birth_month', birthMonth);
    setOrRemove('birth_year', birthYear);
    setOrRemove('gender', gender?.name);
    setOrRemove('blood_type', bloodType?.name);
    setOrRemove('emergency_contact', phone);

    // El seguro se guarda en `seguro_medico`; se quitan las claves del
    // paramédico para que no contradigan lo que capturó el médico
    for (final k in const [
      'has_medical_insurance',
      'has_insurance',
      'insurance',
    ]) {
      out.remove(k);
    }
    setOrRemove('seguro_medico', insurance?.storedValue);
    setOrRemove(
      'insurance_institution',
      insurance == MedicoWalkInInsurance.si ? institution : null,
    );

    setOrRemove('allergies', allergies);
    setOrRemove('medications', medications);
    setOrRemove('medical_history', medicalHistory);
    return out;
  }

  /// Copia de [vitalSigns] con los valores canónicos; los vacíos y los alias
  /// antiguos se quitan
  Map<String, dynamic> applyToVitalSigns(Map<String, dynamic> vitalSigns) {
    final out = Map<String, dynamic>.from(vitalSigns);
    vitalKeys.forEach((key, aliases) {
      for (final a in aliases) {
        out.remove(a);
      }
      final v = (vitals[key] ?? '').trim().replaceAll(',', '.');
      if (v.isEmpty) {
        out.remove(key);
      } else {
        out[key] = v;
      }
    });
    return out;
  }
}
