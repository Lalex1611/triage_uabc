import 'package:flutter/material.dart';

class PatientActionsData {
  /* / Callback al presionar "CANCELAR". */
  final VoidCallback onCancelTap;

  /* / Callback al presionar "CONFIRMAR". */
  final VoidCallback onConfirmTap;

  const PatientActionsData({
    required this.onCancelTap,
    required this.onConfirmTap,
  });
}
