import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_name_input_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_name_input_widget.dart';

/*
  COMANDO PARA PROBAR ESTE WIDGET AISLADO:
  flutter run -t test/features/paramedico/presentation/start_triage/widgets/start_triage_name_input_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartTriageNameInputSandbox(),
    ),
  );
}

class StartTriageNameInputSandbox extends StatelessWidget {
  const StartTriageNameInputSandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.black, // Fondo negro puro
        body: SafeArea(
          child: Center(
            child: StartTriageNameInputWidget(
              data: StartTriageNameInputData(
                onChanged: (text) => debugPrint('Texto actual: \$text'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
