import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_role_title_data.dart';

class MedicoQueueRoleTitleWidget extends StatelessWidget {
  final MedicoQueueRoleTitleData data;

  const MedicoQueueRoleTitleWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.roleLabel,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.userName,
            style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${data.currentPatientCount} pacientes actualmente',
              style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
