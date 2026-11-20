import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_stats_data.dart';

class MedicoQueueStatsWidget extends StatelessWidget {
  final MedicoQueueStatsData data;

  const MedicoQueueStatsWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatCard(
          count: data.enCaminoCount,
          label: 'En camino',
          backgroundColor: Colors.white,
          textColor: AppColors.primaryMedico,
          hasBorder: true,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          count: data.rojosCriticosCount,
          label: 'Rojos/Críticos',
          backgroundColor: AppColors.triageHosp_rojo,
          textColor: Colors.white,
          hasBorder: false,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          count: data.enColaCount,
          label: 'En cola',
          backgroundColor: Colors.white,
          textColor: AppColors.primaryMedico,
          hasBorder: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required int count,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required bool hasBorder,
  }) {
    Border? border;
    if (hasBorder) {
      border = Border.all(
        color: AppColors.primaryMedico.withValues(alpha: 0.5),
        width: 1,
      );
    } else {
      border = Border.all(color: Colors.white, width: 0.35);
    }

    return Container(
      width: 105,
      height: 80,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
              color: textColor,
              fontSize: 32,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
