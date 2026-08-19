// Test visual aislado del Paso 1: Vía Aérea.
//
// Run:
// flutter run -t test/features/paramedico/presentation/start_triage/widgets/guided_level_1_airway_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_1_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_1_widget.dart';

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
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: GuidedProtocolStep1Widget(
            data: GuidedProtocolStep1Data(
              onYesTap: () => debugPrint('Sí respira tap'),
              onNoTap: () => debugPrint('No respira tap'),
            ),
          ),
        ),
      ),
    );
  }
}
