import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/app_module_bottom_nav.dart';

// Barra de navegación inferior del módulo paramédico:
// Mapa · Incidentes · (+) · Guía START · Perfil
class ParamedicoNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Acción del botón "+" central (crear incidente)
  final VoidCallback onCreateIncident;

  const ParamedicoNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCreateIncident,
  });

  // Índices de las pestañas (el "+" no cuenta: no es pestaña)
  static const int mapTab = 0;
  static const int incidentsTab = 1;
  static const int guideTab = 2;
  static const int profileTab = 3;

  // TODO: sustituir el ícono de Guía START por el de Figma cuando exista en TriageIcons
  static const _tabs = [
    AppModuleBottomNavTab(iconPath: TriageIcons.map, label: 'Mapa'),
    AppModuleBottomNavTab(iconPath: TriageIcons.list, label: 'Incidentes'),
    AppModuleBottomNavTab(iconPath: TriageIcons.list, label: 'Guía START'),
    AppModuleBottomNavTab(iconPath: TriageIcons.user, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppModuleBottomNav(
      tabs: _tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: TriageColors.paramedicAccent,
      inactiveColor: TriageColors.textSecondary,
      centerAction: _CreateIncidentButton(onTap: onCreateIncident),
    );
  }
}

class _CreateIncidentButton extends StatelessWidget {
  const _CreateIncidentButton({required this.onTap});

  final VoidCallback onTap;

  // Medidas que solo tiene esta pieza
  static const double _size = 64;
  static const double _iconSize = 32;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Crear incidente',
      child: Material(
        color: TriageColors.paramedicAccent,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: _size,
            height: _size,
            // Si existe un TriageIcons de "más", cámbialo aquí
            child: Icon(
              Icons.add,
              size: _iconSize,
              color: TriageColors.textInverse,
            ),
          ),
        ),
      ),
    );
  }
}