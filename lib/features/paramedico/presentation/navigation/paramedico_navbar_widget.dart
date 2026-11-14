import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/app_module_bottom_nav.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

// Barra de navegación inferior del módulo paramédico:
// Mapa · Incidentes · (+) · Guía START · Perfil
class ParamedicoNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Acción del botón "+" central (crear incidente). En Figma solo está en
  /// el mapa: sin acción no se muestra y las pestañas ocupan su hueco.
  final VoidCallback? onCreateIncident;

  const ParamedicoNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCreateIncident,
  });

  // Índices de las pestañas (el "+" no cuenta: no es pestaña)
  static const int mapTab = 0;
  static const int incidentsTab = 1;
  static const int guideTab = 2;
  static const int profileTab = 3;

  static const _tabs = [
    AppModuleBottomNavTab(iconPath: TriageIcons.map, label: 'Mapa'),
    AppModuleBottomNavTab(iconPath: TriageIcons.list, label: 'Incidentes'),
    // Sin pantalla todavía (B19 · Guía rápida START)
    AppModuleBottomNavTab(
      iconPath: TriageIcons.clipboard,
      label: 'Guía START',
      enabled: false,
    ),
    AppModuleBottomNavTab(iconPath: TriageIcons.user, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final create = onCreateIncident;
    return AppModuleBottomNav(
      tabs: _tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: TriageColors.paramedicAccent,
      // Figma usa el terciario; el secundario es el que llega a 4.5:1
      inactiveColor: TriageColors.textSecondary,
      centerAction: create == null
          ? null
          : _CreateIncidentButton(onTap: create),
    );
  }
}

/// Botón rojo con aro rosa que sobresale de la píldora
class _CreateIncidentButton extends StatelessWidget {
  const _CreateIncidentButton({required this.onTap});

  final VoidCallback onTap;

  // Figma: el "+" ocupa tres cuartos del botón
  static const double _iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final size = context.rDim(AppModuleBottomNav.centerActionSize);

    return Semantics(
      button: true,
      label: 'Crear incidente',
      // El aro también responde: la zona táctil es el círculo completo
      child: Material(
        color: TriageColors.triageRedBackground,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Padding(
              padding: const EdgeInsets.all(TriageSpacing.xs),
              // Ink: la onda del toque se pinta encima del rojo
              child: Ink(
                decoration: const ShapeDecoration(
                  color: TriageColors.paramedicAccent,
                  shape: CircleBorder(),
                ),
                child: Center(
                  child: TriageIcon(
                    TriageIcons.plus,
                    size: context.rDim(_iconSize),
                    color: TriageColors.textInverse,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
