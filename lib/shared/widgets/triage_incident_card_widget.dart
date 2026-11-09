import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_level_count_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_tap_card_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    // Figma usa texto terciario (3.05:1); el secundario llega a 4.5:1
    final meta = TriageTextStyles.labelSmall.copyWith(
      color: TriageColors.textSecondary,
    );

    return TriageTapCard(
      onTap: onTap,
      selected: selected,
      borderColor: selected
          ? context.triageRole.accent
          : TriageColors.borderSubtle,
      borderWidth: selected ? TriageSizes.strokeStrong : TriageSizes.stroke,
      shadow: selected ? TriageShadows.card : TriageShadows.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(folio, style: meta)),
              const SizedBox(width: TriageSpacing.sm),
              Flexible(
                child: Text(timeAgo, style: meta, textAlign: TextAlign.end),
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
          TriageLevelTotals(counts: counts, patientCount: patientCount),
        ],
      ),
    );
  }
}
