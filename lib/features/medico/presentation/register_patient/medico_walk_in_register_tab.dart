import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_institution.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_walk_in_insurance.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_assessment_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_bottom_bar_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_identification_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_success_data.dart';
import 'package:sistema_triage/features/medico/domain/services/medico_patient_form_validators.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_assessment_step_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_bottom_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_identification_step_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_success_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';

/// Registro en dos pasos de un paciente que llega por su cuenta al hospital
/// (sin traslado / sin incidente). Mockups 07 (identificación), 08 (valoración)
/// y 09 (confirmación). El paciente queda como «recibido» en el hospital del médico.
class MedicoWalkInRegisterTab extends StatefulWidget {
  const MedicoWalkInRegisterTab({
    super.key,
    required this.onSuccessfullyRegistered,
    required this.onClose,
    this.repository,
  });

  /// "Ver en la sala" en la confirmación (mockup 09)
  final Future<void> Function(String patientId) onSuccessfullyRegistered;

  /// Cierra el registro (botón X / "Cancelar"). Si ya se registró a alguien,
  /// [registered] es true para que quien lo use recargue la lista.
  final void Function({required bool registered}) onClose;
  final PatientsRepository? repository;

  @override
  State<MedicoWalkInRegisterTab> createState() =>
      _MedicoWalkInRegisterTabState();
}

class _MedicoWalkInRegisterTabState extends State<MedicoWalkInRegisterTab> {
  late final PatientsRepository _patientsRepo;
  final _scrollController = ScrollController();

  /// 1 = identificación, 2 = valoración
  int _step = 1;
  bool _saving = false;

  /// Resultado del registro; cuando no es null se muestra la confirmación
  ({String patientId, String consultationCode, String name})? _registered;

  /// Se registró al menos un paciente desde que se abrió la pestaña;
  /// "Registrar otro paciente" no lo borra (el inicio debe recargar al cerrar)
  bool _anyRegistered = false;

  // Paso 1
  String? _photoPath;
  final _name = TextEditingController();
  final _birthDay = TextEditingController();
  final _birthMonth = TextEditingController();
  final _birthYear = TextEditingController();
  final _phone = TextEditingController();
  MedicoPatientGender? _gender;
  PatientBloodType? _bloodType;
  MedicoWalkInInsurance? _insurance;
  String? _institution;
  final _otherInstitution = TextEditingController();

  // Paso 2
  MedicoTriageCategory? _triage;
  final _reason = TextEditingController();
  final _allergies = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _heartRate = TextEditingController();
  final _respiratoryRate = TextEditingController();
  final _temperature = TextEditingController();
  final _oxygen = TextEditingController();
  final _glucose = TextEditingController();

  List<TextEditingController> get _controllers => [
    _name,
    _birthDay,
    _birthMonth,
    _birthYear,
    _phone,
    _otherInstitution,
    _reason,
    _allergies,
    _systolic,
    _diastolic,
    _heartRate,
    _respiratoryRate,
    _temperature,
    _oxygen,
    _glucose,
  ];

  @override
  void initState() {
    super.initState();
    _patientsRepo = widget.repository ?? PatientsRepository();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validación y armado del payload
  // ---------------------------------------------------------------------------

  String? _birthDateError() => MedicoPatientFormValidators.birthDateError(
    _birthDay.text,
    _birthMonth.text,
    _birthYear.text,
  );

  String? _phoneError() => MedicoPatientFormValidators.phoneError(_phone.text);

  /// Nombre de la institución elegida ("Otra" toma lo escrito)
  String _institutionText() => _institution == MedicoInsuranceInstitution.other
      ? _otherInstitution.text.trim()
      : (_institution ?? '');

  Map<String, dynamic> _buildDemographics() {
    final demo = <String, dynamic>{
      'description': _reason.text.trim(),
      'photo_local_paths': [?_photoPath],
    };

    final bd = int.tryParse(_birthDay.text.trim());
    final bm = int.tryParse(_birthMonth.text.trim());
    final by = int.tryParse(_birthYear.text.trim());
    if (bd != null) demo['birth_day'] = bd;
    if (bm != null) demo['birth_month'] = bm;
    if (by != null) demo['birth_year'] = by;
    if (_gender != null) demo['gender'] = _gender!.name;
    if (_bloodType != null) demo['blood_type'] = _bloodType!.name;

    final phone = _phone.text.trim();
    if (phone.isNotEmpty) demo['emergency_contact'] = phone;

    final insurance = _insurance?.storedValue;
    if (insurance != null) demo['seguro_medico'] = insurance;
    final institution = _institutionText();
    if (_insurance == MedicoWalkInInsurance.si && institution.isNotEmpty) {
      demo['insurance_institution'] = institution;
    }

    final allergies = _allergies.text.trim();
    if (allergies.isNotEmpty) demo['allergies'] = allergies;

    return demo;
  }

  Map<String, dynamic> _buildVitals() {
    final m = <String, dynamic>{};
    void put(String k, TextEditingController c) {
      final t = c.text.trim().replaceAll(',', '.');
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

  /// Signos vitales escritos que no son un número (p. ej. "36..5")
  String? _vitalsError() {
    final fields = [
      ('presión sistólica', _systolic),
      ('presión diastólica', _diastolic),
      ('frecuencia cardiaca', _heartRate),
      ('frecuencia respiratoria', _respiratoryRate),
      ('temperatura', _temperature),
      ('saturación de oxígeno', _oxygen),
      ('glucosa', _glucose),
    ];
    for (final (label, c) in fields) {
      if (!MedicoPatientFormValidators.isValidVital(c.text)) {
        return 'Revisa el valor de $label.';
      }
    }
    return null;
  }

  static String _triageSql(MedicoTriageCategory c) => c.name;

  // ---------------------------------------------------------------------------
  // Navegación entre pasos
  // ---------------------------------------------------------------------------

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onContinue() {
    if (_name.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Escribe el nombre del paciente o "desconocido".',
        isError: true,
      );
      return;
    }
    final dateError = _birthDateError();
    if (dateError != null) {
      showAppSnackBar(context, dateError, isError: true);
      return;
    }
    final phoneError = _phoneError();
    if (phoneError != null) {
      showAppSnackBar(context, phoneError, isError: true);
      return;
    }
    if (_insurance == MedicoWalkInInsurance.si &&
        _institution == MedicoInsuranceInstitution.other &&
        _otherInstitution.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Escribe el nombre de la institución del seguro.',
        isError: true,
      );
      return;
    }
    _goToStep(2);
  }

  Future<void> _onSubmit() async {
    if (_saving) return;

    if (_triage == null) {
      showAppSnackBar(context, 'Selecciona un nivel de triage.', isError: true);
      return;
    }
    if (_reason.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Describe el motivo de consulta.',
        isError: true,
      );
      return;
    }
    final vitalsError = _vitalsError();
    if (vitalsError != null) {
      showAppSnackBar(context, vitalsError, isError: true);
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

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final result = await _patientsRepo.registerWalkInPatient(
        triageColor: _triageSql(_triage!),
        displayName: _name.text,
        demographics: _buildDemographics(),
        vitalSigns: _buildVitals(),
        reasonForVisit: _reason.text,
      );
      _anyRegistered = true;
      if (!mounted) return;
      setState(
        () => _registered = (
          patientId: result.patientId,
          consultationCode: result.consultationCode,
          name: _name.text.trim(),
        ),
      );
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } catch (e) {
      if (mounted) showAppSnackBar(context, _errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// "Registrar otro paciente": limpia todo y vuelve al paso 1
  void _resetForm() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _registered = null;
      _step = 1;
      _photoPath = null;
      _gender = null;
      _bloodType = null;
      _insurance = null;
      _institution = null;
      _triage = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _close() => widget.onClose(registered: _anyRegistered);

  Future<void> _showFamilyCode() async {
    final r = _registered;
    if (r == null) return;
    await ConsultationCodeQrDialog.show(
      context,
      code: r.consultationCode,
      title: 'Código para la familia',
    );
  }

  static String _errorText(Object e) {
    final s = e.toString();
    // PostgrestException(message: ..., code: ...) → solo el mensaje
    final match = RegExp(r'message: ([^,]+)').firstMatch(s);
    return match?.group(1)?.trim() ?? s;
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final img = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (img != null && mounted) setState(() => _photoPath = img.path);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'No se pudo abrir la cámara o la galería.',
          isError: true,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_registered != null) return _buildSuccess(_registered!);
    final isFirst = _step == 1;

    // Es una pestaña del inicio: el Back del sistema nunca cierra la ruta
    // que la contiene. En el paso 1 cierra el registro; en el 2 regresa al 1
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        if (isFirst) {
          _close();
        } else {
          _goToStep(1);
        }
      },
      child: ColoredBox(
        color: MedicoWalkInColors.background,
        child: Column(
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
                      ? _close
                      : () {
                          if (!_saving) _goToStep(1);
                        },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: isFirst ? _identificationStep() : _assessmentStep(),
              ),
            ),
            MedicoWalkInBottomBar(
              data: isFirst
                  ? MedicoWalkInBottomBarData(
                      primaryLabel: 'Continuar a valoración',
                      onPrimaryTap: _onContinue,
                    )
                  : MedicoWalkInBottomBarData(
                      primaryLabel: 'Registrar paciente',
                      onPrimaryTap: () => unawaited(_onSubmit()),
                      isLoading: _saving,
                      secondaryLabel: 'Cancelar',
                      onSecondaryTap: _close,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmación del registro (mockup 09)
  Widget _buildSuccess(
    ({String patientId, String consultationCode, String name}) r,
  ) {
    final triage = _triage ?? MedicoTriageCategory.azul;
    final level =
        MedicoTriageLevel.levelOf(TriageCategory.values.byName(triage.name)) ??
        5;
    final folio = IncidentPresentationFormatters.shortPatientId(r.patientId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: ColoredBox(
        color: MedicoWalkInColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: MedicoWalkInHeader(
                data: MedicoWalkInHeaderData(
                  title: 'Paciente registrado',
                  subtitle: '$folio · ${r.name}',
                  leadingIcon: Icons.close,
                  onLeadingTap: _close,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: MedicoWalkInSuccess(
                  data: MedicoWalkInSuccessData(
                    patientName: r.name,
                    level: level,
                    levelColorName: triage.code.toLowerCase(),
                    consultationCode: r.consultationCode,
                    isFemale: _gender == MedicoPatientGender.femenino,
                    onFamilyCodeTap: () => unawaited(_showFamilyCode()),
                  ),
                ),
              ),
            ),
            MedicoWalkInBottomBar(
              data: MedicoWalkInBottomBarData(
                primaryLabel: 'Ver en la sala',
                onPrimaryTap: () =>
                    unawaited(widget.onSuccessfullyRegistered(r.patientId)),
                secondaryLabel: 'Registrar otro paciente',
                onSecondaryTap: _resetForm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identificationStep() {
    return MedicoWalkInIdentificationStep(
      data: MedicoWalkInIdentificationData(
        photoPath: _photoPath,
        onAddPhotoTap: () => unawaited(_pickPhoto()),
        onRemovePhotoTap: () => setState(() => _photoPath = null),
        nameController: _name,
        birthDayController: _birthDay,
        birthMonthController: _birthMonth,
        birthYearController: _birthYear,
        phoneController: _phone,
        gender: _gender,
        onGenderChanged: (g) => setState(() => _gender = g),
        bloodType: _bloodType,
        onBloodTypeChanged: (b) => setState(() => _bloodType = b),
        insurance: _insurance,
        onInsuranceChanged: (i) => setState(() => _insurance = i),
        institution: _institution,
        onInstitutionChanged: (v) => setState(() => _institution = v),
        otherInstitutionController: _otherInstitution,
      ),
    );
  }

  Widget _assessmentStep() {
    return MedicoWalkInAssessmentStep(
      data: MedicoWalkInAssessmentData(
        selectedLevel: _triage,
        onLevelSelected: (c) {
          if (_saving) return;
          setState(() => _triage = c);
        },
        reasonController: _reason,
        allergiesController: _allergies,
        systolicController: _systolic,
        diastolicController: _diastolic,
        heartRateController: _heartRate,
        respiratoryRateController: _respiratoryRate,
        temperatureController: _temperature,
        oxygenController: _oxygen,
        glucoseController: _glucose,
      ),
    );
  }
}
