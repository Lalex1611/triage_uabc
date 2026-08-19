import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Badge compacto del mapa que resume la cantidad de incidentes activos
class ActiveIncidentsMapBadge extends StatelessWidget {
  final int count;

  const ActiveIncidentsMapBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 34,
        padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
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
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryParamedico,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Incidentes activos',
              style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                fontSize: 12,
                color: Colors.black,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
