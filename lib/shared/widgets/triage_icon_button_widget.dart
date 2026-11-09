import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Fondo de [TriageIconButton]: gris sobre tarjetas, blanco con sombra sobre mapas
enum TriageIconButtonVariant { sunken, surface }

/// Tamaño de [TriageIconButton]: círculo con zona táctil de 48, o recuadro a la
/// altura de un botón grande para la barra de acciones
enum TriageIconButtonSize { compact, large }

/// Botón de solo ícono del rediseño (ordenar y filtrar en B02, controles del
/// mapa, código de consulta en B13 y C06)
///
/// [tooltip] es obligatorio: es lo que anuncia el lector de pantalla. Sin
/// [onPressed] se muestra desactivado.
class TriageIconButton extends StatelessWidget {
  const TriageIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = TriageIconButtonVariant.sunken,
    this.size = TriageIconButtonSize.compact,
  });

  /// Ruta de `TriageIcons`
  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final TriageIconButtonVariant variant;
  final TriageIconButtonSize size;

  static const _compactDiameter = 38.0;

  @override
  Widget build(BuildContext context) {
    final isCompact = size == TriageIconButtonSize.compact;
    final isSurface = variant == TriageIconButtonVariant.surface;
    final radius = BorderRadius.circular(
      isCompact ? TriageRadii.full : TriageRadii.lg,
    );
    final side = isCompact
        ? context.rDim(_compactDiameter)
        : TriageSizes.controlLarge;
    final touchSide = isCompact
        ? TriageSizes.touchTarget
        : TriageSizes.controlLarge;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      style: isCompact
          ? null
          : IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
      constraints: BoxConstraints.tightFor(width: touchSide, height: touchSide),
      icon: Opacity(
        opacity: onPressed == null ? TriageOpacity.disabled : 1,
        child: Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSurface ? TriageColors.surface : TriageColors.sunken,
            borderRadius: radius,
            boxShadow: isSurface ? TriageShadows.base : null,
          ),
          child: TriageIcon(
            icon,
            size: isCompact ? TriageSizes.icon : TriageSizes.iconLarge,
            color: TriageColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
