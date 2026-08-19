// Test visual aislado de los datos personales del paciente (médico).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/widgets/medico_register_personal_data_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_option.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_personal_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_personal_data_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Demo(),
  ));
}

class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  MedicoPatientGender? _gender;
  MedicoInsuranceOption? _insurance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: MedicoRegisterPersonalDataWidget(
            data: MedicoRegisterPersonalData(
              birthDay: null,
              birthMonth: null,
              birthYear: null,
              gender: _gender,
              contactNumber: null,
              insurance: _insurance,
              onDayChanged: (v) => debugPrint('day: $v'),
              onMonthChanged: (v) => debugPrint('month: $v'),
              onYearChanged: (v) => debugPrint('year: $v'),
              onGenderChanged: (g) => setState(() => _gender = g),
              onContactNumberChanged: (v) => debugPrint('phone: $v'),
              onInsuranceChanged: (i) => setState(() => _insurance = i),
            ),
          ),
        ),
      ),
    );
  }
}
