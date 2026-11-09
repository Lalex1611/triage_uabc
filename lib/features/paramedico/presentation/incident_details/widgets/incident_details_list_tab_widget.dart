import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_triage_filters_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Pestaña Lista de la vista de detalles de incidente
class IncidentDetailsListTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final PatientTriageFiltersData triageFiltersData;
  final String emptyMessage;
  final List<PatientCardData> patientCards;

  const IncidentDetailsListTab({
    super.key,
    required this.onRefresh,
    required this.triageFiltersData,
    required this.emptyMessage,
    required this.patientCards,
  });

  @override
  Widget build(BuildContext context) {
    final gutter = context.horizontalPadding;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TriageColors.paramedicAccent,
      backgroundColor: TriageColors.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: TriageSpacing.md),
        children: [
          PatientTriageFilters(data: triageFiltersData),
          const SizedBox(height: TriageSpacing.md),
          if (emptyMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: gutter,
                vertical: TriageSpacing.xxl,
              ),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
            )
          else
            ...patientCards.map((data) {
              final displayName = data.name.trim().isNotEmpty
                  ? data.name
                  : 'Paciente sin nombre';
              final code = data.id.isNotEmpty ? data.id : 'Sin código';

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  0,
                  gutter,
                  TriageSpacing.md,
                ),
                child: TriagePatientCard(
                  name: displayName,
                  detail: [code, data.dateStr, ?data.note].join(' · '),
                  level: data.triageLevel,
                  badge: TriageStatusBadge.patient(data.status),
                  onTap: data.onCardTap,
                ),
              );
            }),
        ],
      ),
    );
  }
}
