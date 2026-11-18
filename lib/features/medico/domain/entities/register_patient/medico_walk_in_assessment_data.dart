import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';

/// Paso 2 del registro sin traslado (mockup 08): nivel de triage hospitalario,
/// motivo de consulta y signos vitales opcionales
class MedicoWalkInAssessmentData {
  final MedicoTriageCategory? selectedLevel;
  final ValueChanged<MedicoTriageCategory> onLevelSelected;

  final TextEditingController reasonController;
  final TextEditingController allergiesController;

  final TextEditingController systolicController;
  final TextEditingController diastolicController;
  final TextEditingController heartRateController;
  final TextEditingController respiratoryRateController;
  final TextEditingController temperatureController;
  final TextEditingController oxygenController;
  final TextEditingController glucoseController;

  const MedicoWalkInAssessmentData({
    required this.selectedLevel,
    required this.onLevelSelected,
    required this.reasonController,
    required this.allergiesController,
    required this.systolicController,
    required this.diastolicController,
    required this.heartRateController,
    required this.respiratoryRateController,
    required this.temperatureController,
    required this.oxygenController,
    required this.glucoseController,
  });
}
