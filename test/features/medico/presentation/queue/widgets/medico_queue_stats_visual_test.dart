// Test visual aislado de las 3 stat cards de la cola del médico.
//
// Run:
// flutter run -t test/features/medico/presentation/queue/widgets/medico_queue_stats_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_stats_data.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_stats_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Demo(),
  ));
}

class _Demo extends StatelessWidget {
  const _Demo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryMedico,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: const MedicoQueueStatsWidget(
            data: MedicoQueueStatsData(
              enCaminoCount: 2,
              rojosCriticosCount: 2,
              enColaCount: 7,
            ),
          ),
        ),
      ),
    );
  }
}
