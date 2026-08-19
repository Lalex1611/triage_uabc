// Test visual aislado de la tarjeta de paciente de la cola del médico.
//
// Run:
// flutter run -t test/features/medico/presentation/queue/widgets/medico_queue_patient_card_visual_test.dart

import 'package:flutter/material.dart';
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
        patientId: 'PAC-28320',
        level: 1,
        category: MedicoTriageCategory.rojo,
        patientLine: 'Paciente Numero 1 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 5 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open 1'),
        onCallTap: () => debugPrint('call 1'),
      ),
      MedicoQueuePatientCardData(
        patientId: 'PAC-28321',
        level: 2,
        category: MedicoTriageCategory.amarillo,
        patientLine: 'Paciente Numero 2 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 12 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open 2'),
        onCallTap: () => debugPrint('call 2'),
      ),
      MedicoQueuePatientCardData(
        patientId: 'PAC-28322',
        level: 4,
        category: MedicoTriageCategory.verde,
        patientLine: 'Paciente Numero 3 - 12-Mar-2026 14:32 - Blvd. 2000',
        ingressLabel: 'Ingresó hace 20 minutos',
        registrationDateTime: '12/03/206 14:32:54',
        onCardTap: () => debugPrint('open 3'),
        onCallTap: () => debugPrint('call 3'),
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
