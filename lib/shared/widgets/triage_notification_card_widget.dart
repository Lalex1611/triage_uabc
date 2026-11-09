import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/core/theme/triage_tone.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_tap_card_widget.dart';

/// Tarjeta de notificación del rediseño (C12)
///
/// [tone] colorea el recuadro de [icon]. Sin leer ([unread]): fondo blanco, sombra
/// y un punto que el lector de pantalla anuncia como "Sin leer"; leída: integrada
/// con el fondo. Toda la tarjeta responde a [onTap] y crece con el texto.
class TriageNotificationCard extends StatelessWidget {
  const TriageNotificationCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.onTap,
    this.unread = false,
  });

  /// Ruta de `TriageIcons`
  final String icon;
  final TriageTone tone;
  final String title;
  final String message;
  final String timeAgo;
  final VoidCallback onTap;
  final bool unread;

  static const _symbolSize = 42.0;
  static const _dotSize = 8.0;

  @override
  Widget build(BuildContext context) {
    final dotSize = context.rDim(_dotSize);

    return TriageTapCard(
      onTap: onTap,
      color: unread ? TriageColors.surface : TriageColors.canvas,
      borderColor: TriageColors.borderSubtle,
      shadow: unread ? TriageShadows.card : null,
      padding: const EdgeInsets.all(TriageSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: TriageSpacing.md,
        children: [
          SizedBox.square(
            dimension: context.rDim(_symbolSize),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(TriageRadii.md),
              ),
              child: Center(
                child: TriageIcon(
                  icon,
                  size: TriageSizes.icon,
                  color: tone.color,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: TriageSpacing.xxs,
              children: [
                Row(
                  spacing: TriageSpacing.sm,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TriageTextStyles.labelLarge.copyWith(
                          color: TriageColors.textPrimary,
                        ),
                      ),
                    ),
                    if (unread)
                      Semantics(
                        label: 'Sin leer',
                        child: SizedBox.square(
                          dimension: dotSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.triageRole.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  message,
                  style: TriageTextStyles.bodySmall.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                ),
                Text(
                  timeAgo,
                  // Figma usa texto terciario (3.05:1); el secundario llega a 4.5:1
                  style: TriageTextStyles.labelSmall.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
