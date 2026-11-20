import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_triage_filters_data.dart';
import 'package:sistema_triage/shared/widgets/triage_pressable_widget.dart';

// Barra de filtros horizontales para segmentar la lista de pacientes del médico (mockup 01)
class MedicoTriageFilters extends StatelessWidget {
  final MedicoTriageFiltersData data;

  const MedicoTriageFilters({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: [
          ...MedicoPatientFilter.values.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(filter),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(MedicoPatientFilter filter) {
    final isSelected = data.activeFilter == filter;

    return TriagePressable(
      onTap: () => data.onFilterChanged(filter),
      builder: (context, pressed) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: triagePressedShadow(pressed: pressed),
        ),
        alignment: Alignment.center,
        child: Text(
          filter.label,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
