// Test visual aislado de la sección de Datos extra (médico).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_extra_data_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_extra_data_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_extra_data_widget.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: MedicoRegisterExtraDataWidget(
            data: MedicoRegisterExtraDataData(
              onAllergiesChanged: (v) => debugPrint('allergies: $v'),
              onMedicationsChanged: (v) => debugPrint('meds: $v'),
              onMedicalHistoryChanged: (v) => debugPrint('hist: $v'),
            ),
          ),
        ),
      ),
    );
  }
}
