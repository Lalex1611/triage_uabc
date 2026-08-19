import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/incident_card_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/home/widgets/incident_card_visual_test.dart
*/
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IncidentCardVisualTest(),
    ),
  );
}

class IncidentCardVisualTest extends StatelessWidget {
  const IncidentCardVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de prueba (MOCK)
    final mockIncident = IncidentForCards(
      id: '#INC-729',
      name_card: '12-Mar-2026 14:32 - Blvd. 2000',
      dateTime: DateTime.now(),
      latitude: 32.4841,
      longitude: -116.8920,
      red: 2,
      yellow: 3,
      green: 5,
      black: 1,
      totalVictims: 11,
      isMine: true,
    );

    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor:
            Colors.grey[200], // Fondo gris para que resalte la tarjeta blanca
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VISTA PREVIA DE TARJETA',
                  style: AppTextStyles.ESC_Bold_titleLarge,
                ),
                const SizedBox(height: 20),
                IncidentCard(incident: mockIncident),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
