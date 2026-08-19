import 'package:flutter/foundation.dart';

class StartTriageHeaderData {
  final int patientNumber;
  final VoidCallback onCloseTap;
  /// Título principal del encabezado (p. ej. «Protocolo guiado» en flujo solo-guiado)
  final String headline;

  StartTriageHeaderData({
    required this.patientNumber,
    required this.onCloseTap,
    this.headline = 'START TRIAGE',
  });
}
