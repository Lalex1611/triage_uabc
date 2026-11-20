import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_filter_chips_data.dart';

class MedicoQueueFilterChipsWidget extends StatelessWidget {
  final MedicoQueueFilterChipsData data;

  const MedicoQueueFilterChipsWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: MedicoQueueFilter.values.map(_buildChip).toList()),
    );
  }

  Widget _buildChip(MedicoQueueFilter filter) {
    final bool isSelected = data.selectedFilter == filter;

    Color background = Colors.white;
    Color textColor = AppColors.primaryMedico;
    Color borderColor = AppColors.primaryMedico;
    if (isSelected) {
      background = AppColors.primaryMedico;
      textColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => data.onFilterSelected(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            filter.label,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
