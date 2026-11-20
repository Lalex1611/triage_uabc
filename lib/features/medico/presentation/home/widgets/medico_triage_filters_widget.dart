import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_triage_filters_data.dart';

// Barra de filtros horizontales para segmentar la lista de pacientes del médico
class MedicoTriageFilters extends StatelessWidget {
  final MedicoTriageFiltersData data;

  const MedicoTriageFilters({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 25),
      child: Row(
        children: MedicoPatientFilter.values.asMap().entries.map((entry) {
          final filter = entry.value;
          final isLast = entry.key == MedicoPatientFilter.values.length - 1;

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

  Widget _buildChip(MedicoPatientFilter filter) {
    final isSelected = data.activeFilter == filter;

    Color currentColor = AppColors.inactive;
    if (isSelected) {
      currentColor = AppColors.primaryMedico;
    }

    return GestureDetector(
      onTap: () => data.onFilterChanged(filter),
      child: Container(
        height: 25.56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.65),
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
            fontSize: 10.58,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
