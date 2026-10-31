import 'package:flutter/material.dart';
//import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
//import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Entidad de dominio que transporta la información de un paciente
class PatientCardData {
  final String id;
  final int number;
  final TriageLevel triageLevel;
  final String name;
  final String dateStr;
  final PatientLifecycleStatus status;
  final VoidCallback? onEditTap;
  final VoidCallback? onMapTap;
  final VoidCallback? onCardTap;

  const PatientCardData({
    required this.id,
    required this.number,
    required this.triageLevel,
    required this.name,
    required this.dateStr,
    required this.status,
    this.onEditTap,
    this.onMapTap,
    this.onCardTap,
  });
}
