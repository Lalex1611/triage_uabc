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
class AppModuleBottomNav extends StatelessWidget {
  const AppModuleBottomNav({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<AppModuleBottomNavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        TriageSpacing.xl,
        TriageSpacing.sm,
        TriageSpacing.xl,
        TriageSpacing.sm,
      ),
      child: DecoratedBox(
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
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _NavTab(
                      tab: tabs[i],
                      color: i == currentIndex ? activeColor : inactiveColor,
                      isActive: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
