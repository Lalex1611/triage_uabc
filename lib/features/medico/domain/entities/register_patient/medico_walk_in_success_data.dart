import 'package:flutter/material.dart';

/// Confirmación del registro sin traslado (mockup 09): mensaje "Ya está en la
/// sala" y acceso al código de consulta para la familia
class MedicoWalkInSuccessData {
  final String patientName;

  /// Nivel de triage hospitalario (1–5)
  final int level;

  /// Nombre del color en minúsculas, p. ej. "naranja"
  final String levelColorName;

  final String consultationCode;

  /// Para concordar el texto: "registrada / la acompañe" o "registrado / lo acompañe"
  final bool isFemale;

  final VoidCallback onFamilyCodeTap;

  const MedicoWalkInSuccessData({
    required this.patientName,
    required this.level,
    required this.levelColorName,
    required this.consultationCode,
    required this.isFemale,
    required this.onFamilyCodeTap,
  });
}
