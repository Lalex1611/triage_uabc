import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';

/// Tarjeta de paciente de la Sala (mockup 05): nivel, nombre, estado y
/// subtítulo. Al tocarla se abre el paciente ([MedicoQueuePatientCardData.onTap]).
class MedicoQueuePatientCardWidget extends StatelessWidget {
  final MedicoQueuePatientCardData data;

  const MedicoQueuePatientCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildLevelBox(),
            const SizedBox(width: 10),
            Expanded(child: _buildContent()),
            const Icon(Icons.chevron_right, color: AppColors.inactive),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBox() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: data.levelColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NIVEL',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 8,
              letterSpacing: 0.5,
              height: 1,
            ),
          ),
          Text(
            data.level?.toString() ?? '—',
            style: AppTextStyles.ESC_Black_displayLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                  color: Colors.black,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildStatusPill(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          data.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: AppColors.inactive,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    final s = data.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '• ${s.label}',
        style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
          color: s.foreground,
          fontSize: 9,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
