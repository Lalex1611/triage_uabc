// Test visual aislado de la tarjeta de paciente de la cola del médico.
//
// Run:
// flutter run -t test/features/medico/presentation/queue/widgets/medico_queue_patient_card_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/queue/widgets/medico_queue_patient_card_widget.dart';

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
    final cards = [
      MedicoQueuePatientCardData(
        level: 1,
        levelColor: MedicoTriageCategory.rojo.color,
        name: 'Alberto Pérez',
        status: MedicoQueuePatientStatus.recibido,
        subtitle: 'Hace 4 min · del incidente INC-729',
        onTap: () => debugPrint('open 1'),
      ),
      MedicoQueuePatientCardData(
        level: 2,
        levelColor: MedicoTriageCategory.naranja.color,
        name: 'Lourdes Carrillo',
        status: MedicoQueuePatientStatus.enEspera,
        subtitle: 'Hace 22 min · llegó por su cuenta',
        onTap: () => debugPrint('open 2'),
      ),
      MedicoQueuePatientCardData(
        level: 4,
        levelColor: MedicoTriageCategory.verde.color,
        name: 'Sofía Ibarra',
        status: MedicoQueuePatientStatus.alta,
        subtitle: 'Hace 51 min · llegó por su cuenta',
        onTap: () => debugPrint('open 3'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: cards.length,
          itemBuilder: (context, i) =>
              MedicoQueuePatientCardWidget(data: cards[i]),
        ),
      ),
    );
  }
}
