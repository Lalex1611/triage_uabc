import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_option_text_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_tap_card_widget.dart';

/// Opción grande del rediseño (Figma "TRIAGE/Opción grande", B11): ícono, título,
/// una línea que explica cuándo usarla y chevron
///
/// El ícono toma el color del rol activo; con [neutral], gris (tono "Neutro").
/// [highlighted] marca con un borde del color del rol la opción que se sugiere
/// (START guiado en B11). [tinted] da fondo tenue, borde y símbolo del color del
/// rol a una opción que debe destacar sin ser la sugerida (Emergencias en B11).
/// Toda la tarjeta responde a [onTap] y crece con el texto.
class TriageLargeOption extends StatelessWidget {
  const TriageLargeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.neutral = false,
    this.highlighted = false,
    this.tinted = false,
  }) : assert(!(neutral && tinted));

  /// Ruta de [TriageIcons]
  final String icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool neutral;
  final bool highlighted;
  final bool tinted;

  static const _symbolSize = 50.0;

  @override
  Widget build(BuildContext context) {
    final role = context.triageRole;
    final (Color symbolColor, Color iconColor) = tinted
        ? (role.accent, TriageColors.textInverse)
        : neutral
        ? (TriageColors.sunken, TriageColors.textPrimary)
        : (role.soft, role.accent);

    return TriageTapCard(
      onTap: onTap,
      color: tinted ? role.soft : TriageColors.surface,
      borderColor: highlighted || tinted
          ? role.accent
          : TriageColors.borderMedium,
      borderWidth: highlighted ? TriageSizes.strokeStrong : TriageSizes.stroke,
      shadow: TriageShadows.card,
      child: Row(
        children: [
          SizedBox.square(
            dimension: context.rDim(_symbolSize),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: symbolColor,
                borderRadius: BorderRadius.circular(TriageRadii.lg),
              ),
              child: Center(
                child: TriageIcon(
                  icon,
                  size: TriageSizes.iconLarge,
                  color: iconColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: TriageSpacing.md),
          Expanded(
            child: TriageOptionText(
              title: title,
              detail: detail,
              titleStyle: TriageTextStyles.titleSmall,
            ),
          ),
          const SizedBox(width: TriageSpacing.md),
          const TriageIcon(
            TriageIcons.chevronRight,
            size: TriageSizes.icon,
            color: TriageColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
