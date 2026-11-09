import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Fondo de [TriageIconButton]: gris sobre tarjetas, blanco con sombra sobre
/// mapas, sin fondo (encabezados, hojas y campos) o translúcido sobre la banda
/// del color del rol
enum TriageIconButtonVariant { sunken, surface, plain, onAccent }

/// Tamaño de [TriageIconButton]: pequeño para dentro de un campo (zona táctil
/// de 44), círculo con zona táctil de 48, o recuadro a la altura de un botón
/// grande para la barra de acciones
enum TriageIconButtonSize { small, compact, large }

/// Botón de solo ícono del rediseño (ordenar y filtrar en B02, controles del
/// mapa, código de consulta en B13 y C06, encabezados y hojas)
///
/// [tooltip] es obligatorio: es lo que anuncia el lector de pantalla. Sin
/// [onPressed] se muestra desactivado. [diameter] fija un círculo distinto del
/// estándar (avatar y campana) e [iconSize] un ícono distinto del de su tamaño.
/// [showDot] añade el punto de avisos, con anillo blanco porque el rojo sobre la
/// banda no llega a 3:1 sin él.
class TriageIconButton extends StatelessWidget {
  const TriageIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = TriageIconButtonVariant.sunken,
    this.size = TriageIconButtonSize.compact,
    this.color = TriageColors.textPrimary,
    this.diameter,
    this.iconSize,
    this.showDot = false,
  });

  /// Ruta de `TriageIcons`
  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final TriageIconButtonVariant variant;
  final TriageIconButtonSize size;
  final Color color;
  final double? diameter;
  final double? iconSize;
  final bool showDot;

  static const _compactDiameter = 38.0;

  // Punto de avisos de Figma: diámetro, anillo y posición relativa al círculo
  static const double _dot = 12;
  static const double _dotRing = 2;
  static const _dotAlignment = Alignment(0.5, -0.5);

  @override
  Widget build(BuildContext context) {
    final isLarge = size == TriageIconButtonSize.large;
    final radius = BorderRadius.circular(
      isLarge ? TriageRadii.lg : TriageRadii.full,
    );
    final side = isLarge
        ? TriageSizes.controlLarge
        : diameter ?? context.rDim(_compactDiameter);
    final (double touchSide, double defaultIconSize) = switch (size) {
      TriageIconButtonSize.small => (
        TriageSizes.touchTargetCompact,
        TriageSizes.iconSmall,
      ),
      TriageIconButtonSize.compact => (
        TriageSizes.touchTarget,
        TriageSizes.icon,
      ),
      TriageIconButtonSize.large => (
        TriageSizes.controlLarge,
        TriageSizes.iconLarge,
      ),
    };
    final background = switch (variant) {
      TriageIconButtonVariant.sunken => TriageColors.sunken,
      TriageIconButtonVariant.surface => TriageColors.surface,
      TriageIconButtonVariant.onAccent => TriageColors.overlayOnAccent,
      TriageIconButtonVariant.plain => null,
    };

    final visual = Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: background == null
          ? null
          : BoxDecoration(
              color: background,
              borderRadius: radius,
              boxShadow: variant == TriageIconButtonVariant.surface
                  ? TriageShadows.base
                  : null,
            ),
      child: TriageIcon(icon, size: iconSize ?? defaultIconSize, color: color),
    );

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      style: isLarge
          ? IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: radius),
            )
          : null,
      constraints: BoxConstraints.tightFor(width: touchSide, height: touchSide),
      icon: Opacity(
        opacity: onPressed == null ? TriageOpacity.disabled : 1,
        child: !showDot
            ? visual
            : Stack(
                alignment: _dotAlignment,
                children: [
                  visual,
                  Container(
                    key: const ValueKey('triage-header-dot'),
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      color: TriageColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TriageColors.textInverse,
                        width: _dotRing,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
