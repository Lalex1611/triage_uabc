import 'package:flutter/foundation.dart';

@immutable
class MedicoRegisterActionsData {
  final VoidCallback onCancelTap;
  final VoidCallback onConfirmTap;
  final String cancelLabel;
  final String confirmLabel;

  const MedicoRegisterActionsData({
    required this.onCancelTap,
    required this.onConfirmTap,
    this.cancelLabel = 'CANCELAR',
    this.confirmLabel = 'CONFIRMAR',
  });
}
