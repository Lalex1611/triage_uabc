import 'package:flutter/foundation.dart';

@immutable
class MedicoRegisterHeaderData {
  final String patientId;
  final String patientName;
  final String registrationDateTime;
  final bool showAsterisk;
  final bool isReadOnly;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onEditNameTap;
  final VoidCallback onEditDateTap;
  final VoidCallback onGenerateQrTap;
  final bool isQrEnabled;
  final String qrButtonLabel;

  const MedicoRegisterHeaderData({
    required this.patientId,
    required this.patientName,
    required this.registrationDateTime,
    required this.onNameChanged,
    required this.onEditNameTap,
    required this.onEditDateTap,
    required this.onGenerateQrTap,
    this.isQrEnabled = true,
    this.showAsterisk = true,
    this.isReadOnly = false,
    this.qrButtonLabel = 'Generar Código\nde Consulta',
  });
}
