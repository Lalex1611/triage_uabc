import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';

enum AuthRoleType {
  none,
  paramedico,
  medico;

  Color get primaryColor {
    switch (this) {
      case AuthRoleType.paramedico:
        return const Color(0xFFCE1125); // Rojo
      case AuthRoleType.medico:
      case AuthRoleType.none:
        return const Color(0xFF1D71B8); // Azul
    }
  }

  String get logoAsset {
    switch (this) {
      case AuthRoleType.paramedico:
        return AppIcons.logoParamedico;
      case AuthRoleType.medico:
        return AppIcons.logoMedico;
      case AuthRoleType.none:
        return AppIcons.logoBase;
    }
  }

  String get dropdownText {
    switch (this) {
      case AuthRoleType.paramedico:
        return 'PARAMÉDICO';
      case AuthRoleType.medico:
        return 'MÉDICO';
      case AuthRoleType.none:
        return 'Tipo de Usuario';
    }
  }
}
