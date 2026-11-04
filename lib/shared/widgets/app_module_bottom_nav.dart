import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

class AppModuleBottomNavTab {
  const AppModuleBottomNavTab({required this.iconPath, required this.label});

  final String iconPath;
  final String label;
}

/// Barra de navegación inferior de los módulos (Figma "TRIAGE/Navegación campo"
/// y "TRIAGE/Navegación hospital")
///
/// Píldora con las pestañas repartidas a partes iguales en el ancho disponible;
/// si una etiqueta no cabe se reduce en vez de cortarse.
///
/// Con [centerAction] se reserva un hueco en medio de las pestañas y el widget
/// se dibuja sobresaliendo por arriba de la píldora (botón "+" del módulo campo).
/// Sin [centerAction] la barra es igual que antes.
class AppModuleBottomNav extends StatelessWidget {
  const AppModuleBottomNav({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
    this.centerAction,
  });

  final List<AppModuleBottomNavTab> tabs;

  /// Pestaña activa. Un valor fuera de rango (p. ej. -1) deja todas inactivas.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;
  final Widget? centerAction;

  // Medidas que solo tiene esta pieza
  static const double _centerSlotWidth = 72;
  static const double _centerLift = 14;

  @override
  Widget build(BuildContext context) {
    final action = centerAction;
    final middle = tabs.length ~/ 2;

    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(TriageRadii.full),
        border: Border.all(
          color: TriageColors.borderSubtle,
          width: TriageSizes.hairline,
        ),
        boxShadow: TriageShadows.base,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TriageSpacing.xs),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (action != null && i == middle)
                  const SizedBox(width: _centerSlotWidth),
                Expanded(
                  child: _NavTab(
                    tab: tabs[i],
                    color: i == currentIndex ? activeColor : inactiveColor,
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        TriageSpacing.xl,
        TriageSpacing.sm,
        TriageSpacing.xl,
        TriageSpacing.sm,
      ),
      child: action == null
          ? bar
          // El botón queda dentro de los límites del Stack para que reciba toques
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: _centerLift),
                  child: bar,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [action],
                  ),
                ),
              ],
            ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.tab,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final AppModuleBottomNavTab tab;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isActive,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TriageRadii.full),
          splashColor: color.withValues(alpha: TriageOpacity.pressed),
          highlightColor: color.withValues(alpha: TriageOpacity.hover),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TriageSizes.controlLarge,
            ),
            child: Padding(
              padding: const EdgeInsets.all(TriageSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TriageIcon(
                    tab.iconPath,
                    size: TriageSizes.icon,
                    color: color,
                  ),
                  const SizedBox(height: TriageSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      style: TriageTextStyles.labelSmall.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}