import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/core/theme/triage_tone.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_option_text_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_tap_card_widget.dart';

/// Tarjeta de selección única del rediseño (motivos de C04, seguro médico de B14)
///
/// El padre guarda cuál está elegida. Seleccionada usa el color del rol, o el de
/// [tone] cuando el significado manda (verde en "Sí, tiene seguro"), y lleva una
/// palomita para no depender solo del color. Toda la tarjeta responde a [onTap]
/// y crece con el texto. Para una lista, colocarlas en una `Column` con
/// `spacing: TriageSpacing.md`.
class TriageRadioOption extends StatelessWidget {
  const TriageRadioOption({
    super.key,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.tone,
  });

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;
  final TriageTone? tone;

  static const _indicatorSize = 22.0;
  static const _checkRatio = 13 / 22;

  @override
  Widget build(BuildContext context) {
    final role = context.triageRole;
    final accent = tone?.color ?? role.accent;
    final indicatorSize = context.rDim(_indicatorSize);

    return TriageTapCard(
      onTap: onTap,
      exclusive: true,
      selected: selected,
      color: selected ? tone?.background ?? role.soft : TriageColors.surface,
      borderColor: selected ? accent : TriageColors.borderMedium,
      borderWidth: selected ? TriageSizes.strokeStrong : TriageSizes.stroke,
      child: Row(
        children: [
          SizedBox.square(
            dimension: indicatorSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? accent : TriageColors.surface,
                shape: BoxShape.circle,
                // Figma usa borderStrong, que no llega a 3:1 sobre blanco
                border: Border.all(
                  color: selected ? accent : TriageColors.textTertiary,
                  width: TriageSizes.strokeStrong,
                ),
              ),
              child: selected
                  ? Center(
                      child: TriageIcon(
                        TriageIcons.check,
                        size: indicatorSize * _checkRatio,
                        color: TriageColors.textInverse,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: TriageSpacing.md),
          Expanded(
            child: TriageOptionText(title: title, detail: detail),
          ),
        ],
      ),
    );
  }
}
