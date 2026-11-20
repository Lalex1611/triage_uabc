import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/app_module_bottom_nav.dart';

// Barra de navegación inferior del módulo médico:
// Entrantes · Sala · Registrar · Perfil
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

  static const _tabs = [
    AppModuleBottomNavTab(iconPath: TriageIcons.ambulance, label: 'Entrantes'),
    // Sin pantalla todavía (C05 · Sala hospitalaria)
    AppModuleBottomNavTab(
      iconPath: TriageIcons.hospital,
      label: 'Sala',
      enabled: false,
    ),
    AppModuleBottomNavTab(iconPath: TriageIcons.plus, label: 'Registrar'),
    // Sin pantalla todavía (C13 · Mi perfil)
    AppModuleBottomNavTab(
      iconPath: TriageIcons.user,
      label: 'Perfil',
      enabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppModuleBottomNav(
      tabs: _tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: TriageColors.hospitalAccent,
      inactiveColor: TriageColors.textSecondary,
    );
  }
}
