import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_button_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_level_bar_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_option_text_widget.dart';

/// Banner con el color del nivel de un paciente (Clasificación de B13, C02 y C06)
///
/// [tag] es la línea superior en mayúsculas ("ROJO · INMEDIATO"). Con [onEdit]
/// añade el botón de cambiar la clasificación; con [arrival], la franja de llegada
/// de C02. Los textos son sólidos: el 80 % de opacidad de Figma no siempre llega a
/// 4.5:1. Crece con el texto.
class TriagePatientBanner extends StatelessWidget {
  const TriagePatientBanner({
    super.key,
    required this.level,
    required this.tag,
    required this.title,
    this.detail,
    this.arrival,
    this.onEdit,
    this.editTooltip = 'Cambiar clasificación',
  });

  final TriageLevel level;
  final String tag;
  final String title;
  final String? detail;
  final String? arrival;
  final VoidCallback? onEdit;
  final String editTooltip;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    final arrival = this.arrival;
    final foreground = level.onColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: level.color,
        borderRadius: BorderRadius.circular(TriageRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TriageSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: TriageSpacing.md,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: arrival == null
                        ? TriageSpacing.xxs
                        : TriageSpacing.md,
                    children: [
                      Text(
                        tag,
                        style: TriageTextStyles.labelSmall.copyWith(
                          color: foreground,
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: TriageTextStyles.titleLarge.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                      if (detail != null)
                        Text(
                          detail,
                          style: TriageTextStyles.bodySmall.copyWith(
                            color: foreground,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: TriageSpacing.sm),
                  TriageIconButton(
                    icon: TriageIcons.pencil,
                    tooltip: editTooltip,
                    onPressed: onEdit,
                    variant: TriageIconButtonVariant.onAccent,
                    color: foreground,
                  ),
                ],
              ],
            ),
            if (arrival != null)
              _ArrivalStrip(
                text: arrival,
                // Sobre azul, aclarar el fondo deja el texto blanco en 3.6:1
                background: level == TriageLevel.blue
                    ? Colors.transparent
                    : TriageColors.overlayOnAccent,
                foreground: foreground,
                iconSize: TriageSizes.icon,
                style: TriageTextStyles.labelLarge,
              ),
          ],
        ),
      ),
    );
  }
}

/// Franja con el paciente en curso (traslado B14 a B16): barra de color, nombre y
/// detalle sobre el fondo tenue del nivel. Naranja y azul, sin fondo tenue en
/// Figma, usan gris.
class TriagePatientStrip extends StatelessWidget {
  const TriagePatientStrip({
    super.key,
    required this.level,
    required this.name,
    required this.detail,
  });

  final TriageLevel level;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: level.background ?? TriageColors.sunken,
        borderRadius: BorderRadius.circular(TriageRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TriageSpacing.md),
        child: MergeSemantics(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TriageSpacing.md,
              children: [
                TriageLevelBar(level),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TriageOptionText(title: name, detail: detail),
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

class _ArrivalStrip extends StatelessWidget {
  const _ArrivalStrip({
    required this.text,
    required this.background,
    required this.foreground,
    required this.iconSize,
    required this.style,
  });

  final String text;
  final Color background;
  final Color foreground;
  final double iconSize;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TriageRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TriageSpacing.md,
          vertical: TriageSpacing.sm,
        ),
        child: Row(
          spacing: TriageSpacing.sm,
          children: [
            TriageIcon(
              TriageIcons.ambulance,
              size: iconSize,
              color: foreground,
            ),
            Expanded(
              child: Text(text, style: style.copyWith(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
