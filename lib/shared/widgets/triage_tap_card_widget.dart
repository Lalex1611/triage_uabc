import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Base común de las tarjetas tocables del rediseño: superficie, borde, efecto
/// al tocar y lectura en pantalla
///
/// La usan las opciones, las tarjetas de paciente e incidente y el botón de
/// color; una pantalla normalmente usa esos componentes y no esta directamente.
/// Crece con su contenido y sin [onTap] se anuncia como desactivada. Se anuncia
/// como botón; con [exclusive], como opción de un grupo de selección única.
class TriageTapCard extends StatelessWidget {
  const TriageTapCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color = TriageColors.surface,
    this.borderColor,
    this.borderWidth = TriageSizes.stroke,
    this.shadow,
    this.inkColor,
    this.padding = const EdgeInsets.all(TriageSpacing.lg),
    this.selected,
    this.exclusive = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;

  /// Sin él, la tarjeta no lleva borde
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadow;

  /// Color del efecto al tocar, para tarjetas sobre fondos intensos
  final Color? inkColor;
  final EdgeInsetsGeometry padding;
  final bool? selected;
  final bool exclusive;

  static const _radius = BorderRadius.all(Radius.circular(TriageRadii.xl));

  @override
  Widget build(BuildContext context) {
    final borderColor = this.borderColor;
    final inkColor = this.inkColor;

    return MergeSemantics(
      child: Semantics(
        button: !exclusive,
        enabled: onTap != null,
        selected: exclusive ? null : selected,
        checked: exclusive ? selected : null,
        inMutuallyExclusiveGroup: exclusive ? true : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: _radius,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: _radius,
              splashColor: inkColor?.withValues(alpha: TriageOpacity.pressed),
              highlightColor: inkColor?.withValues(alpha: TriageOpacity.hover),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
