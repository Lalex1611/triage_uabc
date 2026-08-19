import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';

enum MedicoPatientStatus {
  enCamino(
    'En camino (prehospitalario)',
    AppColors.medicoStatus_enCamino,
    canBeSelectedByMedico: false,
  ),
  recibido(
    'Recibido',
    AppColors.medicoStatus_recibido,
    canBeSelectedByMedico: true,
  ),
  enEspera(
    'En espera',
    AppColors.medicoStatus_enEspera,
    canBeSelectedByMedico: false,
  ),
  altaMedica(
    'Alta médica',
    AppColors.medicoStatus_altaMedica,
    canBeSelectedByMedico: true,
  );

  final String label;
  final Color color;
  final bool canBeSelectedByMedico;

  const MedicoPatientStatus(
    this.label,
    this.color, {
    required this.canBeSelectedByMedico,
  });
}
