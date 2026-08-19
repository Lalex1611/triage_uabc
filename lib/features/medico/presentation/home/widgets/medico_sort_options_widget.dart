import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_sorting_options.dart';

// Menú desplegable de opciones de ordenamiento para pacientes del médico
class MedicoSortOptions extends StatelessWidget {
  final MedicoPatientSortOption selectedOption;
  final Function(MedicoPatientSortOption) onOptionSelected;

  const MedicoSortOptions({
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
        children: MedicoPatientSortOption.values.map(_buildOption).toList(),
      ),
    );
  }

  Widget _buildOption(MedicoPatientSortOption option) {
    final isSelected = selectedOption == option;
    return GestureDetector(
      onTap: () => onOptionSelected(option),
      child: Container(
        width: 148,
        height: 57.33,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: (() {
            Color sortOptionColor = Colors.transparent;
            if (isSelected) {
              sortOptionColor = const Color(0xFFF1EFEF);
            }
            return sortOptionColor;
          })(),
          borderRadius: _getBorderRadiusForOption(option),
        ),
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

  BorderRadius _getBorderRadiusForOption(MedicoPatientSortOption option) {
    if (option == MedicoPatientSortOption.recent) {
      return const BorderRadius.vertical(top: Radius.circular(15));
    } else if (option == MedicoPatientSortOption.name) {
      return const BorderRadius.vertical(bottom: Radius.circular(15));
    }
    return BorderRadius.zero;
  }
}
