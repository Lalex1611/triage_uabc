import 'package:flutter/material.dart';
//import 'package:sistema_triage/core/constants/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: PatientTriageFilter.values.asMap().entries.map((entry) {
          final filter = entry.value;
          final isLast = entry.key == PatientTriageFilter.values.length - 1;

          double paddingRight = 8;
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

    // Colores según el diseño blanco
    final backgroundColor = isSelected
        ? const Color(0xFF111827)
        : const Color(0xFFF3F4F6);
    final textColor = isSelected ? Colors.white : const Color(0xFF4B5563);

    return GestureDetector(
      onTap: () => data.onFilterChanged(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 71.34,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          filter.label,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: textColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
