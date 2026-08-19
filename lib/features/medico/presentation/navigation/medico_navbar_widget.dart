import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
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
    AppModuleBottomNavTab(iconPath: AppIcons.medicoNavHome, label: 'Home'),
    AppModuleBottomNavTab(
      iconPath: AppIcons.medicoNavRegistrarPaciente,
      label: 'Registro',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppModuleBottomNav(
      tabs: _tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: AppColors.primaryMedico,
      inactiveColor: AppColors.inactive,
    );
  }
}
