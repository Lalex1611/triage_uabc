import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Opción grande del rediseño (Figma "TRIAGE/Opción grande", B11): ícono, título,
/// una línea que explica cuándo usarla y chevron
///
/// El ícono toma el color del rol activo; con [neutral], gris (tono "Neutro").
/// [highlighted] marca con un borde del color del rol la opción que se sugiere
/// (START guiado en B11). Toda la tarjeta responde a [onTap] y crece con el texto.
class TriageLargeOption extends StatelessWidget {
  const TriageLargeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.neutral = false,
    this.highlighted = false,
  });

  /// Ruta de [TriageIcons]
  final String icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool neutral;
  final bool highlighted;

  static const _radius = BorderRadius.all(Radius.circular(TriageRadii.xl));
  static const _symbolSize = 50.0;

  @override
  Widget build(BuildContext context) {
    final role = context.triageRole;

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TriageColors.surface,
            borderRadius: _radius,
            border: highlighted
                ? Border.all(
                    color: role.accent,
                    width: TriageSizes.strokeStrong,
                  )
                : Border.all(
                    color: TriageColors.borderMedium,
                    width: TriageSizes.stroke,
                  ),
            boxShadow: TriageShadows.card,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: _radius,
              child: Padding(
                padding: const EdgeInsets.all(TriageSpacing.lg),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: _symbolSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: neutral ? TriageColors.sunken : role.soft,
                          borderRadius: BorderRadius.circular(TriageRadii.lg),
                        ),
                        child: Center(
                          child: TriageIcon(
                            icon,
                            size: TriageSizes.iconLarge,
                            color: neutral
                                ? TriageColors.textPrimary
                                : role.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TriageSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TriageTextStyles.titleSmall.copyWith(
                              color: TriageColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: TriageSpacing.xxs),
                          Text(
                            detail,
                            style: TriageTextStyles.bodySmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                        ],
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
