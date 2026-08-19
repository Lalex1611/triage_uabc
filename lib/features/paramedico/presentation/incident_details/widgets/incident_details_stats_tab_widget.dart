import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Pestaña Estadísticas (placeholder) de detalles de incidente
class IncidentDetailsStatsTab extends StatelessWidget {
  const IncidentDetailsStatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Estadísticas\nPróximamente',
          textAlign: TextAlign.center,
          style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
            fontSize: 16,
            color: Colors.black45,
          ),
        ),
      ),
    );
  }
}
