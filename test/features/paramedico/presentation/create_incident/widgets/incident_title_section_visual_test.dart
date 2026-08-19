import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_title_section_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/paramedico/presentation/create_incident/widgets/incident_title_section_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IncidentTitleSectionVisualTest(),
    ),
  );
}

class IncidentTitleSectionVisualTest extends StatelessWidget {
  const IncidentTitleSectionVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: IncidentTitleSection(
            id: 'Nuevo',
            title: '18-marzo-2026 14:32-Boulevard 2000',
            dateStr: '18/03/2026 14:32:54',
            onEditTap: () {},
          ),
        ),
      ),
    );
  }
}
