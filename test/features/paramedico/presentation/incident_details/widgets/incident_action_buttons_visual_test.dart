import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_action_buttons_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/incident_action_buttons_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IncidentActionButtonsVisualTest(),
    ),
  );
}

class IncidentActionButtonsVisualTest extends StatelessWidget {
  const IncidentActionButtonsVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        appBar: AppBar(
          title: const Text(
            'Botones de Acción (Fijos)',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Stack(
          children: [
            // Simular contenido con scroll para demostrar que los botones flotan
            ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: 20,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 50,
                color: Colors.white,
                alignment: Alignment.center,
                child: Text('Contenido de fondo $index'),
              ),
            ),

            // Los botones fijos
            IncidentActionButtons(
              onStartTap: () => print('INICIAR START tocado'),
              onRegisterTap: () => print('REGISTRAR PACIENTE tocado'),
            ),
          ],
        ),
      ),
    );
  }
}
