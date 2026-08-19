import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_list_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_sort_options_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/patient_sort_options_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientSortOptionsVisualTest(),
    ),
  );
}

class PatientSortOptionsVisualTest extends StatefulWidget {
  const PatientSortOptionsVisualTest({super.key});

  @override
  State<PatientSortOptionsVisualTest> createState() =>
      _PatientSortOptionsVisualTestState();
}

class _PatientSortOptionsVisualTestState
    extends State<PatientSortOptionsVisualTest> {
  PatientSortOption _selected = PatientSortOption.recent;
  bool _menuVisible = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Stack(
            children: [
              PatientListHeader(
                data: PatientListHeaderData(
                  patientCount: 8,
                  sortOption: _selected,
                  onSortChanged: (o) => setState(() => _selected = o),
                ),
              ),
              if (_menuVisible)
                Positioned(
                  top: 36,
                  right: 24,
                  child: PatientSortOptions(
                    selectedOption: _selected,
                    onOptionSelected: (option) {
                      setState(() {
                        _selected = option;
                        _menuVisible = false;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
