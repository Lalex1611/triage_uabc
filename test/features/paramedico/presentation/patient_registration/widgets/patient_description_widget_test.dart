import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_description_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_description_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientDescriptionWidgetTest(),
  ));
}

class _PatientDescriptionWidgetTest extends StatefulWidget {
  const _PatientDescriptionWidgetTest();

  @override
  State<_PatientDescriptionWidgetTest> createState() =>
      _PatientDescriptionWidgetTestState();
}

class _PatientDescriptionWidgetTestState
    extends State<_PatientDescriptionWidgetTest> {
  Set<PatientInjuryType> _injuries = {};
  String _description = '';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Test: PatientDescriptionWidget'),
          backgroundColor: const Color(0xFFCE1125),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              PatientDescriptionWidget(
                data: PatientDescriptionData(
                  selectedInjuries: _injuries,
                  descriptionText: _description,
                  onInjuryToggled: (injury) {
                    setState(() {
                      if (_injuries.contains(injury)) {
                        _injuries.remove(injury);
                      } else {
                        _injuries.add(injury);
                      }
                    });
                    debugPrint('Lesión toggled: ${injury.label}');
                  },
                  onDescriptionChanged: (text) {
                    setState(() => _description = text);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lesiones seleccionadas: ${_injuries.map((i) => i.label).join(', ')}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
