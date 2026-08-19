import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';

// Menú desplegable de opciones de ordenamiento para la lista de pacientes
class PatientSortOptions extends StatelessWidget {
  final PatientSortOption selectedOption;
  final Function(PatientSortOption) onOptionSelected;

  const PatientSortOptions({
    super.key,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8B8B8B), width: 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: PatientSortOption.values.map(_buildOption).toList(),
      ),
    );
  }

  Widget _buildOption(PatientSortOption option) {
    final isSelected = selectedOption == option;
    final isFirst = option == PatientSortOption.values.first;
    final isLast = option == PatientSortOption.values.last;

    BorderRadius borderRadius = BorderRadius.zero;
    if (isFirst) {
      borderRadius = const BorderRadius.vertical(top: Radius.circular(15));
    }
    if (isLast) {
      borderRadius = const BorderRadius.vertical(bottom: Radius.circular(15));
    }

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = const Color(0xFFF1EFEF);
    }

    return GestureDetector(
      onTap: () => onOptionSelected(option),
      child: Container(
        width: 148,
        height: 57.33,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
        alignment: Alignment.centerLeft,
        child: Text(
          option.title,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: Colors.black,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
