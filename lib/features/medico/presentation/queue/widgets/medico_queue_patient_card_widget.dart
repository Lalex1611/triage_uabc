import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';
import 'package:sistema_triage/shared/widgets/triage_pressable_widget.dart';

/// Tarjeta de paciente en la Sala (mockup 05): nivel, nombre, estado y origen
class MedicoQueuePatientCardWidget extends StatelessWidget {
  final MedicoQueuePatientCardData data;

  const MedicoQueuePatientCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return TriagePressable(
      onTap: data.onTap,
      builder: (context, pressed) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: triagePressedShadow(pressed: pressed),
        ),
        child: Row(
          children: [
            _levelBadge(),
            const SizedBox(width: 12),
            Expanded(child: _content()),
            const Icon(Icons.chevron_right, color: Colors.black38, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _levelBadge() {
    final fg = data.levelColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    return Container(
      width: 44,
      height: 50,
      decoration: BoxDecoration(
        color: data.levelColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NIVEL',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              color: fg.withValues(alpha: 0.85),
              fontSize: 8,
              letterSpacing: 0.4,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.level?.toString() ?? '—',
            style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
              color: fg,
              fontSize: 24,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
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
                style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _statusPill(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          data.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _statusPill() {
    final status = data.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              fontSize: 10,
              color: status.foreground,
              letterSpacing: 0.4,
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
