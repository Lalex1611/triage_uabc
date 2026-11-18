import 'package:flutter/material.dart';

/// Encabezado del registro sin traslado (mockups 07, 08 y 09): título y,
/// mientras se llena el formulario, el paso actual con barra de progreso.
/// En la confirmación (mockup 09) [currentStep] y [totalSteps] van en null.
class MedicoWalkInHeaderData {
  final String title;
  final String subtitle;
  final int? currentStep;
  final int? totalSteps;
  final IconData leadingIcon;
  final VoidCallback onLeadingTap;

  const MedicoWalkInHeaderData({
    required this.title,
    required this.subtitle,
    this.currentStep,
    this.totalSteps,
    required this.leadingIcon,
    required this.onLeadingTap,
  });

  bool get showsProgress => currentStep != null && totalSteps != null;
}
