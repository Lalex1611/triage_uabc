import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_description_section_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/create_incident/widgets/incident_description_section_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IncidentDescriptionSectionVisualTest(),
    ),
  );
}

class IncidentDescriptionSectionVisualTest extends StatelessWidget {
  const IncidentDescriptionSectionVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: IncidentDescriptionSection()),
      ),
    );
  }
}
