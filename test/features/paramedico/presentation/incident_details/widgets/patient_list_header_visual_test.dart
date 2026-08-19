import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_list_header_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/patient_list_header_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientListHeaderVisualTest(),
    ),
  );
}

class PatientListHeaderVisualTest extends StatelessWidget {
  const PatientListHeaderVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: PatientListHeader(
            data: PatientListHeaderData(
              patientCount: 8,
              sortOption: PatientSortOption.recent,
              onSortChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }
}
