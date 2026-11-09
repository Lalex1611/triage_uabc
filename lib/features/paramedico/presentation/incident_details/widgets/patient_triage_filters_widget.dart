import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Barra de filtros horizontales tipo carrusel para segmentar la lista de pacientes por triage
class PatientTriageFilters extends StatelessWidget {
  final PatientTriageFiltersData data;

  const PatientTriageFilters({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: Row(
        spacing: TriageSpacing.sm,
        children: [
          for (final filter in PatientTriageFilter.values)
            TriageChip(
              label: filter.label,
              selected: data.activeFilter == filter,
              onTap: () => data.onFilterChanged(filter),
            ),
        ],
      ),
    );
  }
}
