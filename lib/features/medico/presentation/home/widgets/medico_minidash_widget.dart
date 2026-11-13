import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_user_stats.dart';

// Panel de estadísticas del Home médico (mockup 01): 3 tarjetas azules con texto blanco
class MedicoMinidash extends StatelessWidget {
  final MedicoUserStats userstats;

  const MedicoMinidash({super.key, required this.userstats});

  Widget _buildStatCard({required String count, required String label}) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3D7EB4),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            textAlign: TextAlign.left,
            style: AppTextStyles.ESC_Bold_displayLarge.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.left,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1C69AA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              count: userstats.enCaminoCount.toString(),
              label: 'En camino',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              count: userstats.rojoCriticoCount.toString(),
              label: 'Críticos',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              count: userstats.enColaCount.toString(),
              label: 'En sala',
            ),
          ),
        ],
      ),
    );
  }
}
