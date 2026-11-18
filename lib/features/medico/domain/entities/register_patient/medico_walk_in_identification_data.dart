import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_walk_in_insurance.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';

/// Paso 1 del registro sin traslado (mockup 07): foto, identificación y seguro
class MedicoWalkInIdentificationData {
  final String? photoPath;
  final VoidCallback onAddPhotoTap;
  final VoidCallback onRemovePhotoTap;

  final TextEditingController nameController;
  final TextEditingController birthDayController;
  final TextEditingController birthMonthController;
  final TextEditingController birthYearController;
  final TextEditingController phoneController;

  final MedicoPatientGender? gender;
  final ValueChanged<MedicoPatientGender?> onGenderChanged;
  final PatientBloodType? bloodType;
  final ValueChanged<PatientBloodType?> onBloodTypeChanged;
  final MedicoWalkInInsurance? insurance;
  final ValueChanged<MedicoWalkInInsurance> onInsuranceChanged;

  const MedicoWalkInIdentificationData({
    required this.photoPath,
    required this.onAddPhotoTap,
    required this.onRemovePhotoTap,
    required this.nameController,
    required this.birthDayController,
    required this.birthMonthController,
    required this.birthYearController,
    required this.phoneController,
    required this.gender,
    required this.onGenderChanged,
    required this.bloodType,
    required this.onBloodTypeChanged,
    required this.insurance,
    required this.onInsuranceChanged,
  });
}
