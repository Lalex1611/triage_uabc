// Test visual aislado del AppBar de detalles del paciente (médico).
//
// Run:
// flutter run -t test/features/medico/presentation/patient_details/widgets/medico_details_app_bar_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_details_app_bar_data.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/widgets/medico_details_app_bar_widget.dart';

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
      appBar: MedicoDetailsAppBarWidget(
        data: MedicoDetailsAppBarData(
          onBackTap: () => debugPrint('back to queue'),
        ),
      ),
      body: const Center(child: Text('AppBar de detalles aislado')),
    );
  }
}
