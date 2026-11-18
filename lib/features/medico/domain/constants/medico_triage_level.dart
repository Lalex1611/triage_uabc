import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/// Nivel de triage hospitalario (1–5) y color de insignia usados en la Sala.
/// Paleta alineada con las tarjetas del Home médico (mockups 01 y 05).
abstract final class MedicoTriageLevel {
  static int? levelOf(TriageCategory c) {
    switch (c) {
      case TriageCategory.rojo:
        return 1;
      case TriageCategory.naranja:
        return 2;
      case TriageCategory.amarillo:
        return 3;
      case TriageCategory.verde:
        return 4;
      case TriageCategory.azul:
        return 5;
      case TriageCategory.negro:
      case TriageCategory.todos:
        return null;
    }
  }

  static Color colorOf(TriageCategory c) {
    switch (c) {
      case TriageCategory.rojo:
        return const Color(0xFFB6070A);
      case TriageCategory.naranja:
        return const Color(0xFFF39223);
      case TriageCategory.amarillo:
        return const Color(0xFFF5C518);
      case TriageCategory.verde:
        return const Color(0xFF2FA835);
      case TriageCategory.azul:
        return const Color(0xFF1D71B8);
      case TriageCategory.negro:
        return const Color(0xFF1A1A1A);
      case TriageCategory.todos:
        return const Color(0xFF8E8E93);
    }
  }
}
