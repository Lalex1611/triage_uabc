import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_detail_header_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/incident_detail_header_visual_test.dart
*/

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const IncidentDetailHeaderVisualTest(),
    ),
  );
}

class IncidentDetailHeaderVisualTest extends StatelessWidget {
  const IncidentDetailHeaderVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: IncidentDetailHeader(
            data: IncidentHeaderData(
              id: 'INC-2026-001',
              createdAtLabel: '12-marzo-2026 14:32',
              title: '12-Mar-2026 14:32 - Blvd. 2000',
              latitude: 19.4326,
              longitude: -99.1332,
              gpsCoordinates: '19.43260, -99.13320',
              hasGps: true,
              isEditable: true,
              redCount: 1,
              yellowCount: 2,
              greenCount: 50,
              blackCount: 0,
              totalPatients: 8,
            ),
          ),
        ),
      ),
    );
  }
}
