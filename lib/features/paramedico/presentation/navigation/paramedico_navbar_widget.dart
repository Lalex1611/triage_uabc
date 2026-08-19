import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
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
    AppModuleBottomNavTab(iconPath: AppIcons.paramedicoNavHome, label: 'Home'),
    AppModuleBottomNavTab(
      iconPath: AppIcons.paramedicoNavIncidente,
      label: 'Incidente',
    ),
    AppModuleBottomNavTab(iconPath: AppIcons.paramedicoNavMapa, label: 'Mapa'),
    AppModuleBottomNavTab(
      iconPath: AppIcons.paramedicoNavUnicoPaciente,
      label: 'Paciente',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppModuleBottomNav(
      tabs: _tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: AppColors.primaryParamedico,
      inactiveColor: AppColors.inactive,
    );
  }
}
