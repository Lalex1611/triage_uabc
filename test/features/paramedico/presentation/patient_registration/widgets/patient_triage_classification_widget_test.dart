import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_triage_classification_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_triage_classification_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_triage_classification_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientTriageClassificationWidgetTest(),
  ));
}

class _PatientTriageClassificationWidgetTest extends StatefulWidget {
  const _PatientTriageClassificationWidgetTest();

  @override
  State<_PatientTriageClassificationWidgetTest> createState() =>
      _PatientTriageClassificationWidgetTestState();
}

class _PatientTriageClassificationWidgetTestState
    extends State<_PatientTriageClassificationWidgetTest> {
  TriageCategory? _selected;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Test: PatientTriageClassificationWidget'),
          backgroundColor: const Color(0xFFCE1125),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PatientTriageClassificationWidget(
              data: PatientTriageClassificationData(
                selectedCategory: _selected,
                onCategorySelected: (c) {
                  setState(() => _selected = c);
                  debugPrint('Seleccionado: ${c.label}');
                },
              ),
            ),
            const SizedBox(height: 24),
            if (_selected != null)
              Text(
                'Categoría activa: ${_selected!.label}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
