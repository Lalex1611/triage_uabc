import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/app_module_bottom_nav.dart';

// Barra de navegación inferior del módulo médico (mockup 01, sin botón central)
class MedicoNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MedicoNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const int incomingTab = 0;
  static const int wardTab = 1;
  static const int registerTab = 2;
  static const int profileTab = 3;

  static const Color activeColor = Color(0xFF005AA0);

  @override
  Widget build(BuildContext context) {
    return AppModuleBottomNav(
      tabs: const [
        AppModuleBottomNavTab(
          iconPath: TriageIcons.ambulance,
          label: 'Entrantes',
        ),
        AppModuleBottomNavTab(iconPath: TriageIcons.hospital, label: 'Sala'),
        AppModuleBottomNavTab(iconPath: TriageIcons.plus, label: 'Registrar'),
        AppModuleBottomNavTab(iconPath: TriageIcons.user, label: 'Perfil'),
      ],
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: activeColor,
      inactiveColor: TriageColors.textSecondary,
    );
  }
}
