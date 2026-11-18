// Sandbox del registro sin traslado del médico (mockups 07, 08 y 09).
// Ensambla encabezado, pasos y botonera con estado local, sin backend.
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/medico_walk_in_register_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_walk_in_insurance.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_assessment_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_bottom_bar_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_identification_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_success_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_assessment_step_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_bottom_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_identification_step_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_success_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: _Sandbox()),
  );
}

class _Sandbox extends StatefulWidget {
  const _Sandbox();

  @override
  State<_Sandbox> createState() => _SandboxState();
}

class _SandboxState extends State<_Sandbox> {
  int _step = 1;
  MedicoPatientGender? _gender;
  PatientBloodType? _blood;
  MedicoWalkInInsurance? _insurance = MedicoWalkInInsurance.si;
  MedicoTriageCategory? _triage = MedicoTriageCategory.naranja;
  final _c = List.generate(14, (_) => TextEditingController());

  void _log(String s) => debugPrint(s);

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 3) return _success();
    final isFirst = _step == 1;
    return Scaffold(
      backgroundColor: MedicoWalkInColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: MedicoWalkInHeader(
              data: MedicoWalkInHeaderData(
                title: 'Registrar paciente',
                subtitle: isFirst ? 'Llegó por su cuenta' : 'Valoración',
                currentStep: _step,
                totalSteps: 2,
                leadingIcon: isFirst ? Icons.close : Icons.arrow_back,
                onLeadingTap: isFirst
                    ? () => _log('cerrar')
                    : () => setState(() => _step = 1),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: isFirst
                  ? MedicoWalkInIdentificationStep(
                      data: MedicoWalkInIdentificationData(
                        photoPath: null,
                        onAddPhotoTap: () => _log('añadir foto'),
                        onRemovePhotoTap: () {},
                        nameController: _c[0],
                        birthDayController: _c[1],
                        birthMonthController: _c[2],
                        birthYearController: _c[3],
                        phoneController: _c[4],
                        gender: _gender,
                        onGenderChanged: (g) => setState(() => _gender = g),
                        bloodType: _blood,
                        onBloodTypeChanged: (b) => setState(() => _blood = b),
                        insurance: _insurance,
                        onInsuranceChanged: (i) =>
                            setState(() => _insurance = i),
                      ),
                    )
                  : MedicoWalkInAssessmentStep(
                      data: MedicoWalkInAssessmentData(
                        selectedLevel: _triage,
                        onLevelSelected: (t) => setState(() => _triage = t),
                        reasonController: _c[5],
                        allergiesController: _c[6],
                        systolicController: _c[7],
                        diastolicController: _c[8],
                        heartRateController: _c[9],
                        respiratoryRateController: _c[10],
                        temperatureController: _c[11],
                        oxygenController: _c[12],
                        glucoseController: _c[13],
                      ),
                    ),
            ),
          ),
          MedicoWalkInBottomBar(
            data: isFirst
                ? MedicoWalkInBottomBarData(
                    primaryLabel: 'Continuar a valoración',
                    onPrimaryTap: () => setState(() => _step = 2),
                  )
                : MedicoWalkInBottomBarData(
                    primaryLabel: 'Registrar paciente',
                    onPrimaryTap: () => setState(() => _step = 3),
                    secondaryLabel: 'Cancelar',
                    onSecondaryTap: () => setState(() => _step = 1),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _success() {
    return Scaffold(
      backgroundColor: MedicoWalkInColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: MedicoWalkInHeader(
              data: MedicoWalkInHeaderData(
                title: 'Paciente registrado',
                subtitle: 'PAC-2042 · Lourdes Carrillo',
                leadingIcon: Icons.close,
                onLeadingTap: () => setState(() => _step = 1),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: MedicoWalkInSuccess(
                data: MedicoWalkInSuccessData(
                  patientName: 'Lourdes Carrillo',
                  level: 2,
                  levelColorName: 'naranja',
                  consultationCode: 'H4P2QN',
                  isFemale: true,
                  onFamilyCodeTap: () => _log('código familia'),
                ),
              ),
            ),
          ),
          MedicoWalkInBottomBar(
            data: MedicoWalkInBottomBarData(
              primaryLabel: 'Ver en la sala',
              onPrimaryTap: () => _log('ver en la sala'),
              secondaryLabel: 'Registrar otro paciente',
              onSecondaryTap: () => setState(() => _step = 1),
            ),
          ),
        ],
      ),
    );
  }
}
