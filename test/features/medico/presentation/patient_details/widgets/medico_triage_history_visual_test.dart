/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/medico/presentation/patient_details/widgets/medico_triage_history_visual_test.dart
*/

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_triage_history_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/widgets/medico_triage_history_widget.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: _Sandbox(),
          ),
        ),
      ),
    ),
  );
}

class _Sandbox extends StatelessWidget {
  const _Sandbox();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final sampleEntries = [
      PatientTriageHistoryEntry(
        id: 'h3',
        patientId: 'PAC-28321',
        oldTriageColor: MedicoTriageCategory.naranja,
        newTriageColor: MedicoTriageCategory.rojo,
        oldStatus: 'trasladando',
        newStatus: 'recibido',
        actorRole: 'medico',
        changedFields: ['triage_color', 'status'],
        changedAt: now.subtract(const Duration(minutes: 15)),
      ),
      PatientTriageHistoryEntry(
        id: 'h2',
        patientId: 'PAC-28321',
        oldTriageColor: MedicoTriageCategory.amarillo,
        newTriageColor: MedicoTriageCategory.naranja,
        oldStatus: 'en_espera',
        newStatus: 'trasladando',
        actorRole: 'paramedico',
        changedFields: ['triage_color', 'status'],
        changedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      ),
      PatientTriageHistoryEntry(
        id: 'h1',
        patientId: 'PAC-28321',
        oldTriageColor: null,
        newTriageColor: MedicoTriageCategory.amarillo,
        oldStatus: null,
        newStatus: 'registrado',
        actorRole: 'paramedico',
        changedFields: ['created', 'triage_color', 'status'],
        changedAt: now.subtract(const Duration(hours: 3)),
      ),
    ];

    return MedicoTriageHistoryWidget(
      data: MedicoTriageHistoryData(
        entries: sampleEntries,
      ),
    );
  }
}
