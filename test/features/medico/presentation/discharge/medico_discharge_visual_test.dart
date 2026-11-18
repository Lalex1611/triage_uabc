// Sandbox de la pantalla de alta médica del médico (mockup 10), sin backend.
//
// Run:
// flutter run -t test/features/medico/presentation/discharge/medico_discharge_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/presentation/discharge/medico_discharge_page.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MedicoDischargePage(
        folio: 'PAC-2031A7',
        patientName: 'Alberto Pérez',
        onConfirm: (destination, note) async {
          debugPrint('alta: ${destination.dbValue} · nota: $note');
          await Future.delayed(const Duration(seconds: 1));
        },
      ),
    ),
  );
}
