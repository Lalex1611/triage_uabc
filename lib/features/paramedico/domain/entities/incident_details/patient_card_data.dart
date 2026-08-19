import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

// Entidad de dominio que transporta la información de un paciente
class PatientCardData {
  final String id;
  final int number;
  final TriageCategory triageCategory;
  final String name;
  final String dateStr;
  final String coordinates;
  final PatientStatus status;
  final VoidCallback? onEditTap;
  final VoidCallback? onMapTap;
  final VoidCallback? onCardTap;

  PatientCardData({
    required this.id,
    required this.number,
    required this.triageCategory,
    required this.name,
    required this.dateStr,
    required this.coordinates,
    required this.status,
    this.onEditTap,
    this.onMapTap,
    this.onCardTap,
  });
}
