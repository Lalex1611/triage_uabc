import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';

// Catálogo de estados posibles para un paciente durante un incidente
enum PatientStatus {
  registrado('REGISTRADO', Color(0xFFF39B27)), // Naranja
  enEspera(
    'EN ESPERA',
    AppColors.medicoStatus_enEspera,
  ), // Amarillo/ambar de consulta
  trasladando('TRASLADANDO', Color(0xFF3B82F6)), // Azul
  recibido('RECIBIDO', Color(0xFF00C74A)), // Verde
  alta('ALTA', Colors.white); // Blanco (requiere stroke negro en la UI)

  final String label;
  final Color color;

  const PatientStatus(this.label, this.color);
}
