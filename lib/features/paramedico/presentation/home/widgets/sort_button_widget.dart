import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/incident_sorting_options.dart';

// Botón de menú desplegable para seleccionar el criterio de ordenamiento de incidentes
class SortMenu extends StatelessWidget {
  final IncidentSortOption selectedOption;
  final Function(IncidentSortOption) onOptionSelected;

  const SortMenu({
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
        children: IncidentSortOption.values.map(_buildOption).toList(),
      ),
    );
  }

  Widget _buildOption(IncidentSortOption option) {
    final isSelected = selectedOption == option;
    return GestureDetector(
      onTap: () => onOptionSelected(option),
      child: Container(
        width: 148,
        height: 57.33,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: (() {
            Color sortButtonColor = Colors.transparent;
            if (isSelected) {
              sortButtonColor = const Color(0xFFF1EFEF);
            }
            return sortButtonColor;
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

  BorderRadius _getBorderRadiusForOption(IncidentSortOption option) {
    if (option == IncidentSortOption.recent) {
      return const BorderRadius.vertical(top: Radius.circular(15));
    } else if (option == IncidentSortOption.victims) {
      return const BorderRadius.vertical(bottom: Radius.circular(15));
    }
    return BorderRadius.zero;
  }
}
