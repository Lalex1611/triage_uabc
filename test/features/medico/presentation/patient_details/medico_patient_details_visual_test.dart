// Sandbox maestro de la pantalla de detalles del paciente (médico)
// Muestra los datos ya llenados para "Alfonso Villegas"
// El lápiz junto al nombre alterna el modo edición (como la app real)
//
// Run:
// flutter run -t test/features/medico/presentation/patient_details/medico_patient_details_visual_test.dart

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_option.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_details_app_bar_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_triage_history_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_actions_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_description_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_extra_data_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_personal_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_photo_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_status_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_triage_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_vital_signs_data.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/medico_patient_details_page.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/widgets/medico_details_app_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/widgets/medico_triage_history_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_actions_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_description_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_extra_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_personal_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_photo_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_status_dropdown_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_triage_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_vital_signs_widget.dart';

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
  bool _canEdit = true;

  // Modos de edición temporal por sección (solo se usan cuando _canEdit=true).
  bool _isEditingTriage = false;
  bool _isEditingPersonal = false;

  // Datos pre-llenados del paciente "Alfonso Villegas".
  String _name = 'Alfonso Villegas';
  MedicoPatientStatus _status = MedicoPatientStatus.recibido;
  MedicoTriageCategory? _triage = MedicoTriageCategory.rojo;
  final List<String> _photos = ['asset:assets/images/image_placeholder_1.jpg'];
  String? _birthDay = '18';
  String? _birthMonth = '11';
  String? _birthYear = '1993';
  MedicoPatientGender? _gender = MedicoPatientGender.masculino;
  String? _contactNumber = '664 XXX XXXX';
  MedicoInsuranceOption? _insurance = MedicoInsuranceOption.si;
  String _description = 'Presenta hemorragia interna y sangrado nasal';
  String? _systolic = '120';
  String? _diastolic = '80';
  String? _heartRate = '78';
  String? _respiratoryRate = '18';
  String? _temperature = '37.2';
  String? _oxygen = '95';
  String? _glucose = '110';
  String? _allergies = 'Desconocido';
  String? _medications = 'Desconocido';
  String? _medicalHistory = 'Desconocido';

  void _onHeaderEditTap() {
    setState(() {
      _canEdit = !_canEdit;
      if (!_canEdit) {
        _isEditingTriage = false;
        _isEditingPersonal = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MedicoPatientDetailsPage(
      appBar: MedicoDetailsAppBarWidget(
        data: MedicoDetailsAppBarData(
          onBackTap: () => debugPrint('back to queue'),
        ),
      ),
      bodyChildren: _buildBody(),
      bottomActions: MedicoRegisterActionsWidget(
        data: MedicoRegisterActionsData(
          onCancelTap: () => debugPrint('cancel'),
          onConfirmTap: () => debugPrint('save'),
        ),
      ),
    );
  }

  // El triage está bloqueado por defecto en details. Solo se desbloquea
  // mientras `_isEditingTriage` es true. Con el lápiz se entra al modo edición
  // y al elegir un color se vuelve a bloquear.
  bool get _triageEditingEnabled => _canEdit && _isEditingTriage;
  VoidCallback? get _triageEditTap {
    if (!_canEdit) {
      return null;
    }
    return () => setState(() => _isEditingTriage = !_isEditingTriage);
  }

  VoidCallback? get _personalEditTap {
    if (!_canEdit) {
      return null;
    }
    return () => setState(() => _isEditingPersonal = !_isEditingPersonal);
  }

  bool get _personalReadOnly {
    if (!_canEdit) {
      return true;
    }
    return !_isEditingPersonal;
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
          isEditingEnabled: _triageEditingEnabled,
          title: 'Clasificación START',
          onEditTap: _triageEditTap,
          onCategorySelected: (c) {
            setState(() {
              _triage = c;
              _isEditingTriage = false;
            });
          },
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
          isReadOnly: _personalReadOnly,
          onEditTap: _personalEditTap,
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
      const SizedBox(height: 26),
      MedicoTriageHistoryWidget(
        data: MedicoTriageHistoryData(
          entries: [
            PatientTriageHistoryEntry(
              id: 'h2',
              patientId: 'PAC-28321',
              oldTriageColor: MedicoTriageCategory.naranja,
              newTriageColor: MedicoTriageCategory.rojo,
              oldStatus: 'trasladando',
              newStatus: 'recibido',
              actorRole: 'medico',
              changedFields: const ['triage_color', 'status'],
              changedAt: DateTime.now().subtract(const Duration(minutes: 20)),
            ),
            PatientTriageHistoryEntry(
              id: 'h1',
              patientId: 'PAC-28321',
              oldTriageColor: null,
              newTriageColor: MedicoTriageCategory.naranja,
              oldStatus: null,
              newStatus: 'registrado',
              actorRole: 'paramedico',
              changedFields: const ['created', 'triage_color', 'status'],
              changedAt: DateTime.now().subtract(const Duration(hours: 2)),
            ),
          ],
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
            showAsterisk: false,
            isReadOnly: !_canEdit,
            onNameChanged: (v) => _name = v,
            onEditNameTap: _onHeaderEditTap,
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
