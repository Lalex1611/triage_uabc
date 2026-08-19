// Test visual aislado del AppBar de registro de paciente del médico.
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_app_bar_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_app_bar_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_app_bar_widget.dart';

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
      appBar: MedicoRegisterAppBarWidget(
        data: MedicoRegisterAppBarData(
          onBackTap: () => debugPrint('back tapped'),
        ),
      ),
      body: const Center(child: Text('AppBar aislado')),
    );
  }
}
