import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/home_user_stats.dart';

// Panel superior con estadísticas de desempeño y estado actual del usuario activo
class Minidash extends StatelessWidget {
  final HomeUserStats userstats;

  const Minidash({super.key, required this.userstats});

  Widget _buildTriageItemStatsCount(Color color, int count, double size) {
    return Container(
      width: size,
      height: size * (80 / 85),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 0.35),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count.toString(),
            style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompactWidth;
    final nameSize = compact ? 36.0 : 53.0;
    final bottomPad = compact ? 33.0 : 35.0;
    final hPad = context.horizontalPadding + 5;

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.only(top: 5, bottom: bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal de emergencia',
                  style: AppTextStyles.ESC_Regular_bodyLarge.copyWith(
                    color: Colors.white,
                    fontSize: compact ? 13 : 15,
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, compact ? -4 : -8),
                  child: Text(
                    userstats.userName,
                    style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: nameSize,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad + 15),
            child: Column(
              children: [
                Center(
                  child: Text(
                    '${userstats.totalActive} activos',
                    style: AppTextStyles.ESC_Medium_titleLarge.copyWith(
                      color: Colors.white,
                      fontSize: compact ? 18 : 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = compact ? 8.0 : 12.0;
                    final cardSize =
                        ((constraints.maxWidth - gap * 2) / 3).clamp(68.0, 85.0);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTriageItemStatsCount(
                          AppColors.triagePre_rojo,
                          userstats.redCount,
                          cardSize,
                        ),
                        _buildTriageItemStatsCount(
                          AppColors.triagePre_amarillo,
                          userstats.yellowCount,
                          cardSize,
                        ),
                        _buildTriageItemStatsCount(
                          AppColors.triagePre_verde,
                          userstats.greenCount,
                          cardSize,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
