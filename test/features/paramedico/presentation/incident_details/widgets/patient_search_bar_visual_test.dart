import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_search_bar_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/patient_search_bar_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientSearchBarVisualTest(),
    ),
  );
}

class PatientSearchBarVisualTest extends StatelessWidget {
  const PatientSearchBarVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const PatientSearchBar(),
          ),
        ),
      ),
    );
  }
}
