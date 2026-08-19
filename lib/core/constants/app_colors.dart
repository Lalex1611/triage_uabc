import 'package:flutter/material.dart';

class AppColors {
  // UI general
  static const Color searchHint = Color(0xFFB3B3B3);
  static const Color searchBorder = Color(0xFF8F6F6F);
  static const Color inactive = Color(0xFF999A9D);
  static const Color cardBorder = Color(0xFFCECCCC);
  static const Color textSecondary = Color(0xFF7B7B7B);

  // Triage prehospitalario
  static const Color triagePre_rojo = Color(0xFFFF001B);
  static const Color triagePre_amarillo = Color(0xFFCBBB0B);
  static const Color triagePre_verde = Color(0xFF00AA00);
  static const Color triagePre_negro = Color(0xFF000000);

  /* Triage hospitalario (5 niveles del médico) */
  static const Color triageHosp_rojo = Color(0xFFFF001B);
  static const Color triageHosp_naranja = Color(0xFFF39223);
  static const Color triageHosp_amarillo = Color(0xFFFDE400);
  static const Color triageHosp_verde = Color(0xFF2FA835);
  static const Color triageHosp_azul = Color(0xFF1D71B8);
  static const Color triageHosp_negro = Color(0xFF000000);

  /* Estados de paciente del médico */
  static const Color medicoStatus_recibido = Color(0xFF00C74A);
  static const Color medicoStatus_enEspera = Color(0xFFD4AC0D);
  static const Color medicoStatus_enCamino = Color(0xFFE5E5E5);
  static const Color medicoStatus_altaMedica = Color(0xFFB0B0B0);

  // Inputs / formularios
  static const Color inputBorder = Color(0xFFD9D9D9);
  static const Color inputDisabledFill = Color(0xFFF5F5F5);
  static const Color inputHint = Color(0xFFCCCCCC);

  /* Asterisco de campo obligatorio */
  static const Color requiredAsterisk = Color(0xFFCE1125);

  /* Colores de marca por módulo */
  static const Color primaryParamedico = Color(0xFFCE1125);
  static const Color primaryMedico = Color(0xFF1D71B8);
}
