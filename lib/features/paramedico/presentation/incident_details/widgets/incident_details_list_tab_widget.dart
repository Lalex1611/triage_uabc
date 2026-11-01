import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_list_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_triage_filters_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Pestaña Lista de la vista de detalles de incidente
class IncidentDetailsListTab extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final PatientListHeaderData listHeaderData;
  final PatientTriageFiltersData triageFiltersData;
  final String emptyMessage;
  final List<PatientCardData> patientCards;

  const IncidentDetailsListTab({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.listHeaderData,
    required this.triageFiltersData,
    required this.emptyMessage,
    required this.patientCards,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TriageColors.paramedicAccent,
      backgroundColor: TriageColors.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
        children: [
          const SizedBox(height: 16),
          PatientListHeader(data: listHeaderData),
          const SizedBox(height: 12),
          PatientTriageFilters(data: triageFiltersData),
          const SizedBox(height: 16),
          if (emptyMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
              final detailText = '$code • ${data.dateStr}';

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: TriagePatientCard(
                  name: displayName,
                  detail: detailText,
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
