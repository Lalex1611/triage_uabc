import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

class AppModuleBottomNavTab {
  const AppModuleBottomNavTab({
    required this.iconPath,
    required this.label,
    this.enabled = true,
  });

  final String iconPath;
  final String label;

  /// Sin pantalla todavía: se ve atenuada y no responde
  final bool enabled;
}

/// Barra de navegación inferior de los módulos (Figma "TRIAGE/Navegación campo"
/// y "TRIAGE/Navegación hospital")
///
/// Píldora flotante con las pestañas repartidas a partes iguales en el ancho
/// disponible; para que el contenido pase por detrás, el `Scaffold` que la usa
/// lleva `extendBody: true`. En pantallas estrechas cede margen; una etiqueta
/// que no cabe pasa a otra línea por sus espacios y solo se reduce si una
/// palabra no cabe entera.
///
/// Con [centerAction] se reserva un hueco en medio de las pestañas y el widget
/// se dibuja sobresaliendo por arriba de la píldora (botón "+" del módulo campo,
/// de [centerActionSize]).
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

  /// Diámetro del "+" con su aro (Figma: botón de 54 y aro de 4); el hueco
  /// entre las pestañas mide lo mismo
  static const double centerActionSize =
      TriageSizes.controlLarge + 4 * TriageSpacing.xs;

  /// Cuánto sobresale el "+" por encima de la píldora (Figma: un tercio)
  static const double _centerLift = TriageSpacing.xl;

  @override
  Widget build(BuildContext context) {
    final action = centerAction;
    final middle = tabs.length ~/ 2;
    // rDim lo reduce en pantallas estrechas
    final slotWidth = action == null ? 0.0 : context.rDim(centerActionSize);
    final screenWidth = MediaQuery.sizeOf(context).width;

    double labelWidthWith(double margin, double padding) =>
        (screenWidth - 2 * margin - 2 * TriageSpacing.xs - slotWidth) /
            tabs.length -
        2 * padding;

    // Figma usa los márgenes amplios; si una etiqueta no cabe, cede espacio
    final widestLabel = tabs
        .map(
          (tab) => AppResponsive.textWidth(
            context,
            tab.label,
            TriageTextStyles.labelSmall,
          ),
        )
        .reduce(math.max);
    final isRoomy =
        labelWidthWith(TriageSpacing.xl, TriageSpacing.xs) >= widestLabel;
    final margin = isRoomy ? TriageSpacing.xl : TriageSpacing.sm;
    final tabPadding = isRoomy ? TriageSpacing.xs : TriageSpacing.xxs;
    final labelWidth = labelWidthWith(margin, tabPadding);

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
          // Mismo alto en todas: una etiqueta de dos líneas no desalinea íconos
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (action != null && i == middle) SizedBox(width: slotWidth),
                  Expanded(
                    child: _NavTab(
                      tab: tabs[i],
                      color: !tabs[i].enabled
                          ? inactiveColor.withValues(
                              alpha: TriageOpacity.disabled,
                            )
                          : i == currentIndex
                          ? activeColor
                          : inactiveColor,
                      isActive: i == currentIndex,
                      horizontalPadding: tabPadding,
                      labelWidth: labelWidth,
                      onTap: () => onTap(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        TriageSpacing.xxl,
        TriageSpacing.sm,
        TriageSpacing.xxl,
        TriageSpacing.lg,
      ),
      child: action == null
          ? bar
          // El botón queda dentro de los límites del Stack para que reciba toques
          : Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: context.rDim(_centerLift)),
                  child: bar,
                ),
                action,
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
    required this.horizontalPadding,
    required this.labelWidth,
    required this.onTap,
  });

  final AppModuleBottomNavTab tab;
  final Color color;
  final bool isActive;
  final double horizontalPadding;
  final double labelWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TriageTextStyles.labelSmall.copyWith(color: color);
    final longestWord = tab.label
        .split(' ')
        .map((word) => AppResponsive.textWidth(context, word, labelStyle))
        .reduce(math.max);

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: tab.enabled,
        selected: isActive,
        child: InkWell(
          onTap: tab.enabled ? onTap : null,
          borderRadius: BorderRadius.circular(TriageRadii.full),
          splashColor: color.withValues(alpha: TriageOpacity.pressed),
          highlightColor: color.withValues(alpha: TriageOpacity.hover),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TriageSizes.controlLarge,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: TriageSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TriageIcon(
                    tab.iconPath,
                    size: TriageSizes.icon,
                    color: color,
                  ),
                  const SizedBox(height: TriageSpacing.xs),
                  // El ancho nunca baja de la palabra más larga: se parte por
                  // espacios y FittedBox solo actúa si una palabra no cabe
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: math.max(labelWidth, longestWord),
                      child: Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        style: labelStyle,
                      ),
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
