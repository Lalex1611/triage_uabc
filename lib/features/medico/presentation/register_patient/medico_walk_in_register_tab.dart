import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_option.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_actions_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_description_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_extra_data_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_personal_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_photo_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_status_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_triage_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_vital_signs_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_actions_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_description_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_extra_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_personal_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_photo_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_status_dropdown_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_triage_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_vital_signs_widget.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';
import 'package:image_picker/image_picker.dart';

/// Formulario de registro cuando el médico admite un paciente que llega por su cuenta
/// al hospital (sin traslado / sin incidente)
class MedicoWalkInRegisterTab extends StatefulWidget {
  const MedicoWalkInRegisterTab({
    super.key,
    required this.onSuccessfullyRegistered,
    this.repository,
  });

  final Future<void> Function(String patientId) onSuccessfullyRegistered;
  final PatientsRepository? repository;

  @override
  State<MedicoWalkInRegisterTab> createState() =>
      _MedicoWalkInRegisterTabState();
}

class _MedicoWalkInRegisterTabState extends State<MedicoWalkInRegisterTab>
    with AutomaticKeepAliveClientMixin {
  late final PatientsRepository _patientsRepo;

  @override
  void initState() {
    super.initState();
    _patientsRepo = widget.repository ?? PatientsRepository();
  }

  String _patientName = '';
  MedicoTriageCategory? _triageSel;
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

  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  static String _formatNow(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}/${p2(d.month)}/${d.year} ${p2(d.hour)}:${p2(d.minute)}:${p2(d.second)}';
  }

  static String _triageSql(MedicoTriageCategory c) {
    switch (c) {
      case MedicoTriageCategory.rojo:
        return 'rojo';
      case MedicoTriageCategory.naranja:
        return 'naranja';
      case MedicoTriageCategory.amarillo:
        return 'amarillo';
      case MedicoTriageCategory.verde:
        return 'verde';
      case MedicoTriageCategory.azul:
        return 'azul';
    }
  }

  Map<String, dynamic> _buildDemographics() {
    final demo = <String, dynamic>{
      'description': _description.trim(),
      'photo_local_paths': List<String>.from(_photos),
    };

    final bd = _parseTinyInt(_birthDay);
    final bm = _parseTinyInt(_birthMonth);
    final by = _parseTinyInt(_birthYear);
    if (bd != null) demo['birth_day'] = bd;
    if (bm != null) demo['birth_month'] = bm;
    if (by != null) demo['birth_year'] = by;
    if (_gender != null) demo['gender'] = _gender!.name;

    final contact = (_contactNumber ?? '').trim();
    if (contact.isNotEmpty) demo['emergency_contact'] = contact;

    if (_insurance != null) {
      demo['seguro_medico'] = _insurance == MedicoInsuranceOption.si
          ? 'si'
          : 'no';
    }

    final a = (_allergies ?? '').trim();
    final m = (_medications ?? '').trim();
    final h = (_medicalHistory ?? '').trim();
    if (a.isNotEmpty) demo['allergies'] = a;
    if (m.isNotEmpty) demo['medications'] = m;
    if (h.isNotEmpty) demo['medical_history'] = h;

    return demo;
  }

  int? _parseTinyInt(String? s) {
    final t = (s ?? '').trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Map<String, dynamic> _buildVitals() {
    final m = <String, dynamic>{};
    void put(String k, String? v) {
      final t = (v ?? '').trim();
      if (t.isNotEmpty) m[k] = t;
    }

    put('systolic_pressure', _systolic);
    put('diastolic_pressure', _diastolic);
    put('heart_rate', _heartRate);
    put('respiratory_rate', _respiratoryRate);
    put('temperature', _temperature);
    put('oxygen_saturation', _oxygen);
    put('glucose', _glucose);

    return m;
  }

  void _clearForm() {
    setState(() {
      _patientName = '';
      _triageSel = null;
      _photos.clear();
      _birthDay = null;
      _birthMonth = null;
      _birthYear = null;
      _gender = null;
      _contactNumber = null;
      _insurance = null;
      _description = '';
      _systolic = null;
      _diastolic = null;
      _heartRate = null;
      _respiratoryRate = null;
      _temperature = null;
      _oxygen = null;
      _glucose = null;
      _allergies = null;
      _medications = null;
      _medicalHistory = null;
    });
  }

  Future<void> _onSubmit(BuildContext context) async {
    if (_saving) return;

    final name = _patientName.trim();
    if (name.isEmpty) {
      showAppSnackBar(
        context,
        'Indique el nombre del paciente.',
        isError: true,
      );
      return;
    }
    if (_triageSel == null) {
      showAppSnackBar(
        context,
        'Seleccione una clasificación hospitalaria.',
        isError: true,
      );
      return;
    }

    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return;
    }

    final hosp = AuthGate.instance.hospitalId;
    if (hosp == null || hosp.isEmpty) {
      showAppSnackBar(
        context,
        'Su perfil no tiene hospital asignado. Contacte al administrador.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final vitals = _buildVitals();
      final result = await _patientsRepo.registerWalkInPatient(
        hospitalId: hosp,
        triageColor: _triageSql(_triageSel!),
        displayName: name,
        demographics: _buildDemographics(),
        vitalSigns: vitals.isEmpty ? null : vitals,
      );
      if (!context.mounted) return;
      try {
        await ConsultationCodeQrDialog.show(
          context,
          code: result.consultationCode,
          title: 'Paciente registrado',
          confirmLabel: 'Continuar',
        );
      } catch (_) {}
      if (!context.mounted) return;
      showAppSnackBar(context, 'Paciente registrado. Ya figura como recibido.');
      _clearForm();
      await widget.onSuccessfullyRegistered(result.patientId);
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dt = _formatNow(DateTime.now());

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerWithStatus(dt),
                const SizedBox(height: 30),
                MedicoRegisterPhotoWidget(
                  data: MedicoRegisterPhotoData(
                    photos: _photos,
                    isReadOnly: false,
                    onCameraTap: () => unawaited(_pick(ImageSource.camera)),
                    onAddImageTap: () => unawaited(_pick(ImageSource.gallery)),
                    onRemovePhotoTap: (i) =>
                        setState(() => _photos.removeAt(i)),
                  ),
                ),
                const SizedBox(height: 24),
                MedicoRegisterTriageWidget(
                  data: MedicoRegisterTriageData(
                    selectedCategory: _triageSel,
                    isEditingEnabled: true,
                    onCategorySelected: (c) => setState(() => _triageSel = c),
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
                    isReadOnly: false,
                    onDayChanged: (v) => setState(() => _birthDay = v),
                    onMonthChanged: (v) => setState(() => _birthMonth = v),
                    onYearChanged: (v) => setState(() => _birthYear = v),
                    onGenderChanged: (g) => setState(() => _gender = g),
                    onContactNumberChanged: (v) =>
                        setState(() => _contactNumber = v),
                    onInsuranceChanged: (i) => setState(() => _insurance = i),
                  ),
                ),
                const SizedBox(height: 22),
                MedicoRegisterDescriptionWidget(
                  data: MedicoRegisterDescriptionData(
                    descriptionText: _description,
                    isReadOnly: false,
                    onDescriptionChanged: (v) =>
                        setState(() => _description = v),
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
                    isReadOnly: false,
                    onSystolicPressureChanged: (v) =>
                        setState(() => _systolic = v),
                    onDiastolicPressureChanged: (v) =>
                        setState(() => _diastolic = v),
                    onHeartRateChanged: (v) => setState(() => _heartRate = v),
                    onRespiratoryRateChanged: (v) =>
                        setState(() => _respiratoryRate = v),
                    onTemperatureChanged: (v) =>
                        setState(() => _temperature = v),
                    onOxygenSaturationChanged: (v) =>
                        setState(() => _oxygen = v),
                    onGlucoseChanged: (v) => setState(() => _glucose = v),
                  ),
                ),
                const SizedBox(height: 22),
                MedicoRegisterExtraDataWidget(
                  data: MedicoRegisterExtraDataData(
                    allergies: _allergies,
                    medications: _medications,
                    medicalHistory: _medicalHistory,
                    isReadOnly: false,
                    onAllergiesChanged: (v) => setState(() => _allergies = v),
                    onMedicationsChanged: (v) =>
                        setState(() => _medications = v),
                    onMedicalHistoryChanged: (v) =>
                        setState(() => _medicalHistory = v),
                  ),
                ),
                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
        MedicoRegisterActionsWidget(
          data: MedicoRegisterActionsData(
            cancelLabel: 'LIMPIAR',
            confirmLabel: _saving ? 'GUARDANDO…' : 'REGISTRAR',
            onCancelTap: _saving ? () {} : () => _clearForm(),
            onConfirmTap: _saving ? () {} : () => unawaited(_onSubmit(context)),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(source: src, imageQuality: 80);
      if (img != null && mounted) setState(() => _photos.add(img.path));
    } catch (_) {}
  }

  Widget _headerWithStatus(String registrationDateTime) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MedicoRegisterHeaderWidget(
          data: MedicoRegisterHeaderData(
            patientId:
                'Ingreso sin traslado — el ID aparece después de registrar',
            patientName: _patientName,
            registrationDateTime: registrationDateTime,
            showAsterisk: true,
            isReadOnly: false,
            onNameChanged: (v) => _patientName = v,
            onEditNameTap: () {},
            onEditDateTap: () {},
            isQrEnabled: false,
            qrButtonLabel: 'QR disponible\nal registrar',
            onGenerateQrTap: () {
              showAppSnackBar(
                context,
                'Primero registra al paciente. Después podrás abrir su expediente y generar el código QR.',
              );
            },
          ),
        ),
        Positioned(
          right: 20,
          bottom: -16,
          child: MedicoRegisterStatusDropdownWidget(
            data: MedicoRegisterStatusData(
              currentStatus: MedicoPatientStatus.recibido,
              canEdit: false,
              onStatusChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}
