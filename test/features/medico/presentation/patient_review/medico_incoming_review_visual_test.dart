// Sandbox de la revisión de paciente entrante del médico (mockup 02), con
// datos mock y sin backend.
//
// Run:
// flutter run -t test/features/medico/presentation/patient_review/medico_incoming_review_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/medico_incoming_review_page.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: _Sandbox()),
  );
}

class _Sandbox extends StatefulWidget {
  const _Sandbox();

  @override
  State<_Sandbox> createState() => _SandboxState();
}

class _SandboxState extends State<_Sandbox> {
  TriageCategory _triage = TriageCategory.rojo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Stack(
      children: [
        MedicoIncomingReviewPage(
          review: MedicoIncomingReview(
            patientId: '2031a7c0-0000-0000-0000-000000000000',
            displayName: 'Alberto Pérez',
            triage: _triage,
            ageYears: 34,
            incidentId: '729ab000-0000-0000-0000-000000000000',
            emergencyTypeLabel: 'Accidente vehicular',
            paramedicName: 'Carlos Huerta',
            unitCode: 'A-12',
            classifiedAt: now.subtract(const Duration(minutes: 9)),
            estimatedArrivalAt: now.add(const Duration(minutes: 6)),
            regulationFolio: 'REG-55210',
            injuryLabels: const ['Fractura', 'Hemorragia'],
            reportedDescription:
                'Conductor atrapado en el vehículo. Consciente, desorientado, '
                'sangrado activo en pierna derecha controlado con torniquete.',
            hasInsurance: true,
            bloodTypeLabel: 'O+',
            contactPhone: '664 123 4567',
          ),
          onBackTap: () => debugPrint('atrás'),
          onAcceptTap: () => debugPrint('aceptar'),
          onRejectTap: () => debugPrint('rechazar'),
        ),
        Positioned(
          right: 16,
          bottom: 100,
          child: FloatingActionButton.small(
            tooltip: 'Cambiar color',
            onPressed: () => setState(() {
              final all = TriageCategory.values
                  .where((c) => c != TriageCategory.todos)
                  .toList();
              _triage = all[(all.indexOf(_triage) + 1) % all.length];
            }),
            child: const Icon(Icons.palette_outlined),
          ),
        ),
      ],
    );
  }
}
