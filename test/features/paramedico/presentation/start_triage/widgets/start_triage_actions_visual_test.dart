// Test visual aislado de las acciones de Start Triage.
//
// Run:
// flutter run -t test/features/paramedico/presentation/start_triage/widgets/start_triage_actions_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_actions_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_actions_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Demo(),
  ));
}

class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  bool _hasPhotos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sin fotos (hasPhotos = false)',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),
              StartTriageActionsWidget(
                data: StartTriageActionsData(
                  hasPhotos: false,
                  onCancelOrReturn: () => debugPrint('Cancel/Return tap'),
                  onSkip: () => debugPrint('Skip tap'),
                  onRegister: () => debugPrint('Register tap'),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Con fotos (hasPhotos = true)',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),
              StartTriageActionsWidget(
                data: StartTriageActionsData(
                  hasPhotos: true,
                  onCancelOrReturn: () => debugPrint('Cancel/Return tap'),
                  onSkip: () => debugPrint('Skip tap'),
                  onRegister: () => debugPrint('Register tap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
