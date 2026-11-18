import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_filter_chips_data.dart';
import 'package:sistema_triage/shared/widgets/triage_pressable_widget.dart';

/// Chips de la Sala (mockup 05): Todos / En espera / Recibidos / Dados de alta
class MedicoQueueFilterChipsWidget extends StatelessWidget {
  final MedicoQueueFilterChipsData data;

  const MedicoQueueFilterChipsWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in MedicoQueueFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(filter),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(MedicoQueueFilter filter) {
    final isSelected = data.selectedFilter == filter;

    return TriagePressable(
      onTap: () => data.onFilterSelected(filter),
      builder: (context, pressed) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE5E5EA),
          ),
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
