import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/app_module_bottom_nav.dart';

// Barra de navegación inferior del módulo médico
class MedicoNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MedicoNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    AppModuleBottomNavTab(iconPath: TriageIcons.home, label: 'Home'),
    AppModuleBottomNavTab(iconPath: TriageIcons.plus, label: 'Registro'),
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
