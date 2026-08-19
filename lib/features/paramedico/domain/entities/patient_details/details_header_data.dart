import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class DetailsHeaderData {
  final String patientId;
  final String patientName;
  final String gpsCoordinates;
  final TriageCategory triageCategory;
  final bool isEditing;
  final bool showEditButton;
  final VoidCallback onStartEditTap;
  final ValueChanged<String>? onNameChanged;
  final VoidCallback onGenerateQrTap;
  final VoidCallback onShowMapTap;
  final VoidCallback onEditMapTap;

  const DetailsHeaderData({
    required this.patientId,
    required this.patientName,
    required this.gpsCoordinates,
    required this.triageCategory,
    required this.isEditing,
    required this.showEditButton,
    required this.onStartEditTap,
    required this.onGenerateQrTap,
    required this.onShowMapTap,
    required this.onEditMapTap,
    this.onNameChanged,
  });
}
