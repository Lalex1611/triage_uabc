import 'package:flutter/material.dart';

class MedicoIncomingPatientActionsData {
  final String patientName;
  final String currentStatusLabel;
  final VoidCallback onCancelTransferTap;
  final VoidCallback onReceivePatientTap;
  final VoidCallback onCloseTap;

  const MedicoIncomingPatientActionsData({
    required this.patientName,
    required this.currentStatusLabel,
    required this.onCancelTransferTap,
    required this.onReceivePatientTap,
    required this.onCloseTap,
  });
}
