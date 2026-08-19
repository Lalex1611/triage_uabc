import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';

// Barra de filtros horizontales tipo carrusel para segmentar la lista de pacientes por triage
class PatientTriageFilters extends StatelessWidget {
  final PatientTriageFiltersData data;

  const PatientTriageFilters({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 25),
      child: Row(
        children: PatientTriageFilter.values.asMap().entries.map((entry) {
          final filter = entry.value;
          final isLast = entry.key == PatientTriageFilter.values.length - 1;

          double paddingRight = 15;
          if (isLast) {
            paddingRight = 0;
          }

          return Padding(
            padding: EdgeInsets.only(right: paddingRight),
            child: _buildChip(filter),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChip(PatientTriageFilter filter) {
    final isSelected = data.activeFilter == filter;
    const activeColor = AppColors.primaryParamedico;
    const inactiveColor = Color(0xFF999A9D);

    Color currentColor = inactiveColor;
    if (isSelected) {
      currentColor = activeColor;
    }

    return GestureDetector(
      onTap: () => data.onFilterChanged(filter),
      child: Container(
        width: 71.34,
        height: 25.56,
        padding: const EdgeInsets.symmetric(horizontal: 5.65),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.39),
          border: Border.all(color: currentColor, width: 0.36),
        ),
        alignment: Alignment.center,
        child: Text(
          filter.label,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: currentColor,
            fontSize: 9.58,
            fontWeight: isSelected ? FontWeight.w300 : FontWeight.w200,
          ),
        ),
      ),
    );
  }
}
