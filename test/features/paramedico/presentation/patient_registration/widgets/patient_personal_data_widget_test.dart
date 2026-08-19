import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_personal_data_widget.dart';

/*
  flutter run -t test/features/paramedico/presentation/patient_registration/widgets/patient_personal_data_widget_test.dart
*/

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _PatientPersonalDataWidgetTest(),
  ));
}

class _PatientPersonalDataWidgetTest extends StatefulWidget {
  const _PatientPersonalDataWidgetTest();

  @override
  State<_PatientPersonalDataWidgetTest> createState() =>
      _PatientPersonalDataWidgetTestState();
}

class _PatientPersonalDataWidgetTestState
    extends State<_PatientPersonalDataWidgetTest> {
  PatientGender? _gender;
  PatientBloodType? _bloodType;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Test: PatientPersonalDataWidget'),
          backgroundColor: const Color(0xFFCE1125),
        ),
        body: Center(
          child: PatientPersonalDataWidget(
            data: PatientPersonalData(
              gender: _gender,
              bloodType: _bloodType,
              onDayChanged: (v) => debugPrint('Día: $v'),
              onMonthChanged: (v) => debugPrint('Mes: $v'),
              onYearChanged: (v) => debugPrint('Año: $v'),
              onGenderChanged: (g) => setState(() => _gender = g),
              onBloodTypeChanged: (b) => setState(() => _bloodType = b),
              onContactNumberChanged: (v) => debugPrint('Contacto: $v'),
            ),
          ),
        ),
      ),
    );
  }
}
