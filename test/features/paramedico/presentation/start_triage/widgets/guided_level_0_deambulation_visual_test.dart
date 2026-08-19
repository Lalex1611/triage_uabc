// Test visual aislado del Paso 0: Deambulación.
//
// Run:
// flutter run -t test/features/paramedico/presentation/start_triage/widgets/guided_level_0_deambulation_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_0_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_0_widget.dart';

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
      backgroundColor: const Color(0xFF1A1A1A), // Fondo oscuro como en el flujo real
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: GuidedProtocolStep0Widget(
            data: GuidedProtocolStep0Data(
              onYesTap: () => debugPrint('Sí deambula tap'),
              onNoTap: () => debugPrint('No deambula tap'),
            ),
          ),
        ),
      ),
    );
  }
}
