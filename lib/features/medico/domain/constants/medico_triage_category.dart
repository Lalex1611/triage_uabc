import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';

enum MedicoTriageCategory {
  rojo(AppColors.triageHosp_rojo, 'Rojo', 'Reanimación / Emergencia'),
  naranja(AppColors.triageHosp_naranja, 'Naranja', 'Urgencia'),
  amarillo(AppColors.triageHosp_amarillo, 'Amarillo', 'Urgencia Menor'),
  verde(AppColors.triageHosp_verde, 'Verde', 'No Urgencia'),
  azul(AppColors.triageHosp_azul, 'Azul', 'Sin Urgencia');

  final Color color;
  final String code;
  final String label;

  const MedicoTriageCategory(this.color, this.code, this.label);
}
