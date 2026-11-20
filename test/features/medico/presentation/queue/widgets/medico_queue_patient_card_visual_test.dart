// Test visual aislado de la tarjeta de paciente de la Sala (mockup 05).
//
// Run:
// flutter run -t test/features/medico/presentation/queue/widgets/medico_queue_patient_card_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_patient_card_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: _Demo()));
}

class _Demo extends StatelessWidget {
  const _Demo();

  @override
  Widget build(BuildContext context) {
    final cards = [
      MedicoQueuePatientCardData(
        level: 1,
        levelColor: MedicoTriageLevel.colorOf(TriageCategory.rojo),
        name: 'Alberto Pérez',
        status: MedicoQueuePatientStatus.recibido,
        subtitle: 'Hace 4 min · del incidente INC-729',
        onTap: () => debugPrint('open 1'),
      ),
      MedicoQueuePatientCardData(
        level: 3,
        levelColor: MedicoTriageLevel.colorOf(TriageCategory.amarillo),
        name: 'Ramiro Hernández López',
        status: MedicoQueuePatientStatus.enEspera,
        subtitle: 'Hace 35 min · llegó por su cuenta',
        onTap: () => debugPrint('open 2'),
      ),
      MedicoQueuePatientCardData(
        level: 4,
        levelColor: MedicoTriageLevel.colorOf(TriageCategory.verde),
        name: 'Sofía Ibarra',
        status: MedicoQueuePatientStatus.alta,
        subtitle: 'Alta hace 2 h',
        onTap: () => debugPrint('open 3'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              MedicoQueuePatientCardWidget(data: cards[i]),
        ),
      ),
    );
  }
}
