import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_card_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_list_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_search_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_triage_filters_widget.dart';

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
      color: AppColors.primaryParamedico,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
        children: [
          PatientSearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
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
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            )
          else
            ...patientCards.map(
              (data) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: PatientCard(data: data),
              ),
            ),
        ],
      ),
    );
  }
}
