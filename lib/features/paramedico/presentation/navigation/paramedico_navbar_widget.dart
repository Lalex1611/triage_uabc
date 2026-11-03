import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/app_module_bottom_nav.dart';

// Barra de navegación inferior del módulo paramédico
class ParamedicoNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ParamedicoNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    AppModuleBottomNavTab(iconPath: TriageIcons.home, label: 'Home'),
    AppModuleBottomNavTab(iconPath: TriageIcons.list, label: 'Incidente'),
    AppModuleBottomNavTab(iconPath: TriageIcons.map, label: 'Mapa'),
    AppModuleBottomNavTab(iconPath: TriageIcons.user, label: 'Paciente'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppModuleBottomNav(
      tabs: _tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: TriageColors.paramedicAccent,
      inactiveColor: TriageColors.textSecondary,
    );
  }
}
