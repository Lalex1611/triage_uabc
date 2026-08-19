// Test visual aislado de los botones inferiores CANCELAR / CONFIRMAR (médico).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_actions_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_actions_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_actions_widget.dart';

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
      bottomNavigationBar: MedicoRegisterActionsWidget(
        data: MedicoRegisterActionsData(
          onCancelTap: () => debugPrint('cancel'),
          onConfirmTap: () => debugPrint('confirm'),
        ),
      ),
      body: const Center(child: Text('Botones de acción aislados')),
    );
  }
}
