import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Accion flotante para retomar el seguimiento del usuario dentro del mapa
class ResumeNavigationChip extends StatelessWidget {
  final VoidCallback onResume;

  const ResumeNavigationChip({super.key, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onResume,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
              const Icon(
                Icons.navigation_rounded,
                size: 18,
                color: AppColors.primaryParamedico,
              ),
              const SizedBox(width: 8),
              Text(
                'Reanudar',
                style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                  fontSize: 12,
                  color: Colors.black,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
