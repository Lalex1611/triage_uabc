import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_title_section_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/gps_location_picker_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/emergency_type_selector_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/photo_upload_section_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_description_section_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/create_incident_actions_widget.dart';

import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';

/*
  COMANDO PARA PROBAR LA NUEVA PANTALLA: 
  flutter run -t test/features/paramedico/presentation/create_incident/create_incident_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CreateIncidentVisualTest(),
    ),
  );
}

class CreateIncidentVisualTest extends StatelessWidget {
  const CreateIncidentVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: CreateIncidentPage(
        children: [
          const SizedBox(height: 24),
          IncidentTitleSection(
            id: 'Nuevo',
            title: '18-marzo-2026 14:32-Boulevard 2000',
            dateStr: '18/03/2026 14:32:54',
            onEditTap: () {},
          ),
          const SizedBox(height: 24),
          GpsLocationPicker(
            latitude: 19.4326,
            longitude: -99.1332,
            onShowMap: () {},
            onEditManual: () {},
          ),
          const SizedBox(height: 28),
          const EmergencyTypeSelector(
            availableTypes: EmergencyCatalog.standardTypes,
          ),
          const SizedBox(height: 28),
          const PhotoUploadSection(),
          const SizedBox(height: 28),
          const IncidentDescriptionSection(),
          const SizedBox(height: 36),
          const CreateIncidentActions(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
