// Sandbox maestro de la pantalla de registro de paciente del médico.
// Ensambla todos los widgets con datos mock e interactividad local.
// Incluye un FAB para alternar entre modo edición y modo solo lectura
// (simula privilegios sobre el paciente).
//
// Run:
// flutter run -t test/features/medico/presentation/register_patient/medico_register_patient_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_option.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_actions_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_app_bar_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_description_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_extra_data_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_personal_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_photo_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_status_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_triage_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_vital_signs_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/medico_register_patient_page.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_actions_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_app_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_description_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_extra_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_personal_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_photo_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_status_dropdown_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_triage_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_vital_signs_widget.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Sandbox(),
  ));
}

class _Sandbox extends StatefulWidget {
  const _Sandbox();

  @override
  State<_Sandbox> createState() => _SandboxState();
}

class _SandboxState extends State<_Sandbox> {
  bool _canEdit = true;

  String _name = '';
  MedicoPatientStatus _status = MedicoPatientStatus.recibido;
  MedicoTriageCategory? _triage;
  final List<String> _photos = [];
  String? _birthDay;
  String? _birthMonth;
  String? _birthYear;
  MedicoPatientGender? _gender;
  String? _contactNumber;
  MedicoInsuranceOption? _insurance;
  String _description = '';
  String? _systolic;
  String? _diastolic;
  String? _heartRate;
  String? _respiratoryRate;
  String? _temperature;
  String? _oxygen;
  String? _glucose;
  String? _allergies;
  String? _medications;
  String? _medicalHistory;

  void _toggleEdit() {
    setState(() => _canEdit = !_canEdit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _buildToggleFab(),
      body: MedicoRegisterPatientPage(
        appBar: MedicoRegisterAppBarWidget(
          data: MedicoRegisterAppBarData(
            onBackTap: () => debugPrint('back to home'),
          ),
        ),
        bodyChildren: _buildBody(),
        bottomActions: MedicoRegisterActionsWidget(
          data: MedicoRegisterActionsData(
            onCancelTap: () => debugPrint('cancel'),
            onConfirmTap: () => debugPrint('confirm'),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleFab() {
    IconData icon = Icons.edit;
    String label = 'EDIT';
    if (!_canEdit) {
      icon = Icons.visibility;
      label = 'VIEW';
    }
    return FloatingActionButton.extended(
      onPressed: _toggleEdit,
      backgroundColor: AppColors.primaryMedico,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  List<Widget> _buildBody() {
    return [
      _buildHeaderWithStatusPill(),
      const SizedBox(height: 30),
      MedicoRegisterPhotoWidget(
        data: MedicoRegisterPhotoData(
          photos: _photos,
          isReadOnly: !_canEdit,
          onCameraTap: () => debugPrint('camera'),
          onAddImageTap: () => debugPrint('add image'),
          onRemovePhotoTap: (i) => setState(() => _photos.removeAt(i)),
        ),
      ),
      const SizedBox(height: 24),
      MedicoRegisterTriageWidget(
        data: MedicoRegisterTriageData(
          selectedCategory: _triage,
          onCategorySelected: (c) => setState(() => _triage = c),
          isEditingEnabled: _canEdit,
        ),
      ),
      const SizedBox(height: 26),
      MedicoRegisterPersonalDataWidget(
        data: MedicoRegisterPersonalData(
          birthDay: _birthDay,
          birthMonth: _birthMonth,
          birthYear: _birthYear,
          gender: _gender,
          contactNumber: _contactNumber,
          insurance: _insurance,
          isReadOnly: !_canEdit,
          onDayChanged: (v) => _birthDay = v,
          onMonthChanged: (v) => _birthMonth = v,
          onYearChanged: (v) => _birthYear = v,
          onGenderChanged: (g) => setState(() => _gender = g),
          onContactNumberChanged: (v) => _contactNumber = v,
          onInsuranceChanged: (i) => setState(() => _insurance = i),
        ),
      ),
      const SizedBox(height: 22),
      MedicoRegisterDescriptionWidget(
        data: MedicoRegisterDescriptionData(
          descriptionText: _description,
          isReadOnly: !_canEdit,
          onDescriptionChanged: (v) => _description = v,
        ),
      ),
      const SizedBox(height: 26),
      MedicoRegisterVitalSignsWidget(
        data: MedicoRegisterVitalSignsData(
          systolicPressure: _systolic,
          diastolicPressure: _diastolic,
          heartRate: _heartRate,
          respiratoryRate: _respiratoryRate,
          temperature: _temperature,
          oxygenSaturation: _oxygen,
          glucose: _glucose,
          isReadOnly: !_canEdit,
          onSystolicPressureChanged: (v) => _systolic = v,
          onDiastolicPressureChanged: (v) => _diastolic = v,
          onHeartRateChanged: (v) => _heartRate = v,
          onRespiratoryRateChanged: (v) => _respiratoryRate = v,
          onTemperatureChanged: (v) => _temperature = v,
          onOxygenSaturationChanged: (v) => _oxygen = v,
          onGlucoseChanged: (v) => _glucose = v,
        ),
      ),
      const SizedBox(height: 22),
      MedicoRegisterExtraDataWidget(
        data: MedicoRegisterExtraDataData(
          allergies: _allergies,
          medications: _medications,
          medicalHistory: _medicalHistory,
          isReadOnly: !_canEdit,
          onAllergiesChanged: (v) => _allergies = v,
          onMedicationsChanged: (v) => _medications = v,
          onMedicalHistoryChanged: (v) => _medicalHistory = v,
        ),
      ),
      const SizedBox(height: 80),
    ];
  }

  Widget _buildHeaderWithStatusPill() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MedicoRegisterHeaderWidget(
          data: MedicoRegisterHeaderData(
            patientId: 'PAC-28321',
            patientName: _name,
            registrationDateTime: '12/03/2026 14:32:54',
            isReadOnly: !_canEdit,
            onNameChanged: (v) => _name = v,
            onEditNameTap: () => debugPrint('edit name'),
            onEditDateTap: () => debugPrint('edit date'),
            onGenerateQrTap: () => debugPrint('qr'),
          ),
        ),
        Positioned(
          right: 20,
          bottom: -16,
          child: MedicoRegisterStatusDropdownWidget(
            data: MedicoRegisterStatusData(
              currentStatus: _status,
              canEdit: _canEdit,
              onStatusChanged: (s) => setState(() => _status = s),
            ),
          ),
        ),
      ],
    );
  }
}
