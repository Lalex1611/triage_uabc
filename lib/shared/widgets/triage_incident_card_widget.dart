import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_level_count_widget.dart';

/// Tarjeta de incidente del rediseño (Figma "TRIAGE/Tarjeta de incidente", B02)
///
/// Folio y tiempo arriba, título, ubicación y, bajo una línea, el conteo por
/// nivel ([counts], ver [TriageLevelCount]) y el total de pacientes.
/// [selected] la marca con un borde del color del rol activo. Toda la tarjeta
/// responde a [onTap].
class TriageIncidentCard extends StatelessWidget {
  const TriageIncidentCard({
    super.key,
    required this.folio,
    required this.timeAgo,
    required this.title,
    required this.location,
    required this.counts,
    required this.patientCount,
    this.selected = false,
    this.onTap,
  });

  final String folio;
  final String timeAgo;
  final String title;
  final String location;
  final Map<TriageLevel, int> counts;
  final int patientCount;
  final bool selected;
  final VoidCallback? onTap;

  static const _radius = BorderRadius.all(Radius.circular(TriageRadii.xl));

  @override
  Widget build(BuildContext context) {
    // Figma usa texto terciario (3.05:1); el secundario llega a 4.5:1
    final meta = TriageTextStyles.labelSmall.copyWith(
      color: TriageColors.textSecondary,
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        selected: selected,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TriageColors.surface,
            borderRadius: _radius,
            border: selected
                ? Border.all(
                    color: context.triageRole.accent,
                    width: TriageSizes.strokeStrong,
                  )
                : Border.all(
                    color: TriageColors.borderSubtle,
                    width: TriageSizes.stroke,
                  ),
            boxShadow: selected ? TriageShadows.card : TriageShadows.base,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: _radius,
              child: Padding(
                padding: const EdgeInsets.all(TriageSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(folio, style: meta)),
                        const SizedBox(width: TriageSpacing.sm),
                        Flexible(
                          child: Text(
                            timeAgo,
                            style: meta,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TriageSpacing.sm),
                    Text(
                      title,
                      style: TriageTextStyles.titleSmall.copyWith(
                        color: TriageColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: TriageSpacing.sm),
                    Row(
                      children: [
                        const TriageIcon(
                          TriageIcons.location,
                          size: TriageSizes.iconXSmall,
                          color: TriageColors.textTertiary,
                        ),
                        const SizedBox(width: TriageSpacing.xs),
                        Expanded(
                          child: Text(
                            location,
                            style: TriageTextStyles.bodySmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TriageSpacing.sm),
                    const Divider(
                      height: TriageSizes.hairline,
                      thickness: TriageSizes.hairline,
                      color: TriageColors.borderSubtle,
                    ),
                    const SizedBox(height: TriageSpacing.sm),
                    // Conteo a la izquierda y total a la derecha; si no caben
                    // (texto grande) el total baja a otra línea
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: TriageSpacing.sm,
                      runSpacing: TriageSpacing.sm,
                      children: [
                        TriageLevelCount(counts: counts),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TriageIcon(
                              TriageIcons.users,
                              size: TriageSizes.iconXSmall,
                              color: TriageColors.textSecondary,
                            ),
                            const SizedBox(width: TriageSpacing.xs),
                            Flexible(
                              child: Text(
                                patientCount == 1
                                    ? '1 paciente'
                                    : '$patientCount pacientes',
                                style: TriageTextStyles.labelMedium.copyWith(
                                  color: TriageColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
