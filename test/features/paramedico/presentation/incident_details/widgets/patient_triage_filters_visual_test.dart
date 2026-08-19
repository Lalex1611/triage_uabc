import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_triage_filters_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/patient_triage_filters_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientTriageFiltersVisualTest(),
    ),
  );
}

class PatientTriageFiltersVisualTest extends StatefulWidget {
  const PatientTriageFiltersVisualTest({super.key});

  @override
  State<PatientTriageFiltersVisualTest> createState() =>
      _PatientTriageFiltersVisualTestState();
}

class _PatientTriageFiltersVisualTestState
    extends State<PatientTriageFiltersVisualTest> {
  PatientTriageFilter _active = PatientTriageFilter.todos;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: PatientTriageFilters(
            data: PatientTriageFiltersData(
              activeFilter: _active,
              onFilterChanged: (filter) {
                setState(() => _active = filter);
              },
            ),
          ),
        ),
      ),
    );
  }
}
