import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';

class MedicoQueuePatientCardWidget extends StatelessWidget {
  final MedicoQueuePatientCardData data;

  const MedicoQueuePatientCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onCardTap,
      child: Container(
        height: 92,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              _buildLevelBar(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBar() {
    return Container(
      width: 78,
      color: data.category.color,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  data.patientId,
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NIVEL',
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${data.level}',
                  style: AppTextStyles.ESC_Black_displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.patientLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                    color: Colors.black,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.registrationDateTime,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  color: AppColors.inactive,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            data.ingressLabel,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: AppColors.inactive,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: data.onCallTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedico,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Llamar',
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
