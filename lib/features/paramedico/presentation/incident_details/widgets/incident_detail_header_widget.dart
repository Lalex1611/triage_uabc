import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Bloque de datos del incidente bajo el encabezado (B07 a B10): tipo, ubicación,
/// autor y conteo de pacientes
class IncidentDetailHeader extends StatelessWidget {
  final IncidentHeaderData data;

  const IncidentDetailHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final gutter = context.horizontalPadding;

    return ColoredBox(
      color: TriageColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, TriageSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: TriageSpacing.xs,
          children: [
            Semantics(
              header: true,
              child: Text(
                data.title,
                style: TriageTextStyles.screenTitle.copyWith(
                  color: TriageColors.textPrimary,
                ),
              ),
            ),
            _MetaRow(icon: TriageIcons.location, text: data.gpsCoordinates),
            _MetaRow(icon: TriageIcons.clock, text: data.authorLine),
            Padding(
              padding: const EdgeInsets.only(top: TriageSpacing.xs),
              child: TriageLevelTotals(
                counts: {
                  TriageLevel.red: data.redCount,
                  TriageLevel.yellow: data.yellowCount,
                  TriageLevel.green: data.greenCount,
                  TriageLevel.black: data.blackCount,
                },
                patientCount: data.totalPatients,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: TriageSpacing.sm,
      children: [
        TriageIcon(
          icon,
          size: TriageSizes.iconXSmall,
          color: TriageColors.textSecondary,
        ),
        Expanded(
          child: Text(
            text,
            style: TriageTextStyles.bodySmall.copyWith(
              color: TriageColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
