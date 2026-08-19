import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Control de filtro del mapa para alternar entre todos los incidentes y los propios
class MapIncidentFilterChip extends StatelessWidget {
  final bool mineOnly;
  final ValueChanged<bool> onChanged;

  const MapIncidentFilterChip({
    super.key,
    required this.mineOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppColors.cardBorder.withValues(alpha: 0.7),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SegmentButton(
              label: 'TODOS',
              active: !mineOnly,
              onTap: () => onChanged(false),
            ),
            const SizedBox(width: 4),
            _SegmentButton(
              label: 'MIOS',
              active: mineOnly,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 56,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryParamedico : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
            fontSize: 9,
            color: active ? Colors.white : AppColors.textSecondary,
            height: 1,
          ),
        ),
      ),
    );
  }
}
