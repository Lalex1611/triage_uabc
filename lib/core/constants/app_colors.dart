import 'package:flutter/material.dart';

class AppColors {
  // UI general
  static const Color cardBorder = Color(0xFFCECCCC);
  static const Color textSecondary = Color(0xFF7B7B7B);

  // Triage prehospitalario
  static const Color triagePre_rojo = Color(0xFFFF001B);
  static const Color triagePre_amarillo = Color(0xFFFFD600);
  static const Color triagePre_verde = Color(0xFF00AA00);
  static const Color triagePre_negro = Color(0xFF000000);

  /* Triage hospitalario (5 niveles del médico) */
  static const Color triageHosp_rojo = Color(0xFFFF001B);
  static const Color triageHosp_naranja = Color(0xFFF39223);
  static const Color triageHosp_amarillo = Color(0xFFFFD600);
  static const Color triageHosp_verde = Color(0xFF2FA835);
  static const Color triageHosp_azul = Color(0xFF1D71B8);

  /* Estados de paciente del médico */
  static const Color medicoStatus_enEspera = Color(0xFFffc067);

  /* Colores de marca por módulo */
  static const Color primaryParamedico = Color(0xFFCE1125);
  static const Color primaryMedico = Color(0xFF1D71B8);
}
