import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_triage_filters_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_triage_filters_widget.dart';

/*
  COMANDO PARA PROBAR: 
  flutter run -t test/features/medico/presentation/home/widgets/medico_triage_filters_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MedicoTriageFiltersVisualTest(),
    ),
  );
}

class MedicoTriageFiltersVisualTest extends StatelessWidget {
  const MedicoTriageFiltersVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              MedicoTriageFilters(
                data: MedicoTriageFiltersData(
                  activeFilter: MedicoPatientFilter.enCamino,
                  onFilterChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
