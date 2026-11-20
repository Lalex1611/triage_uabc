import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_user_stats.dart';

// Panel superior con estadísticas del médico hospitalario
class MedicoMinidash extends StatelessWidget {
  final MedicoUserStats userstats;

  const MedicoMinidash({super.key, required this.userstats});

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
  }) {
    List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    Border? border;
    if (borderColor != null) {
      border = Border.all(color: borderColor, width: 0.35);
    } else {
      border = Border.all(color: Colors.white, width: 0.35);
    }

    return Container(
      width: 85,
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: shadows,
        border: border,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
              color: textColor,
              fontSize: 32,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: textColor,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = context.isCompactWidth ? 35.0 : 38.0;

    return Container(
      width: double.infinity,
      color: AppColors.primaryMedico,
      padding: EdgeInsets.only(top: 5, bottom: bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información de identificación del usuario con estilo tipográfico destacado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal de hospitalario',
                  style: AppTextStyles.ESC_Regular_bodyLarge.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                // Desplazamiento vertical para compensar el interletrado y espacio natural de la fuente
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Text(
                    userstats.userName,
                    style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 53,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Resumen cuantitativo de pacientes activos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Center(
                  child: Text(
                    '${userstats.totalActive} pacientes actualmente',
                    style: AppTextStyles.ESC_Medium_titleLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      count: userstats.enCaminoCount.toString(),
                      label: 'En camino',
                      bgColor: Colors.white,
                      textColor: AppColors.primaryMedico,
                    ),
                    _buildStatCard(
                      count: userstats.rojoCriticoCount.toString(),
                      label: 'Rojos/Críticos',
                      bgColor: AppColors.triagePre_rojo,
                      textColor: Colors.white,
                    ),
                    _buildStatCard(
                      count: userstats.enColaCount.toString(),
                      label: 'En cola',
                      bgColor: AppColors.primaryMedico,
                      textColor: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
