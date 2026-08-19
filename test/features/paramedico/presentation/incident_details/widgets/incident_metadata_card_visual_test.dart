import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_metadata_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_metadata_card_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/incident_metadata_card_visual_test.dart
*/

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const IncidentMetadataCardVisualTest(),
    ),
  );
}

class IncidentMetadataCardVisualTest extends StatelessWidget {
  const IncidentMetadataCardVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: IncidentMetadataCard(
            data: IncidentMetadataData(
              creatorName: 'Carlos Huerta',
              timeElapsedLabel: '28 minutos',
            ),
          ),
        ),
      ),
    );
  }
}
