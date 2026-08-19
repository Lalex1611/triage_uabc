import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';

class DetailsStatusData {
  final String creatorName;
  final String timeElapsed;
  final PatientStatus currentStatus;
  final bool canEdit;
  final void Function(PatientStatus) onStatusChanged;

  /// Si no es null y no está vacío, sustituye las opciones del menú del chip de estado
  final List<PopupMenuEntry<PatientStatus>>? statusMenuEntries;

  const DetailsStatusData({
    required this.creatorName,
    required this.timeElapsed,
    required this.currentStatus,
    required this.canEdit,
    required this.onStatusChanged,
    this.statusMenuEntries,
  });
}
