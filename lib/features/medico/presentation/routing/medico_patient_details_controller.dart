import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_option.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_incoming_transfer_interactions.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_alta_medica_confirm_dialog.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_demographics_mapper.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';

enum MedicoPatientDetailsShellMode { loading, error, notFound, ready }

/// Lógica y control del expediente del paciente para el rol médico
class MedicoPatientDetailsController extends ChangeNotifier {
  MedicoPatientDetailsController({
    required this.patientId,
    ParamedicoIncidentsRepository? detailRepo,
    PatientsRepository? patientsRepo,
    ImagePicker? picker,
  }) : _detailRepo = detailRepo ?? ParamedicoIncidentsRepository(),
       _patientsRepo = patientsRepo ?? PatientsRepository(),
       _picker = picker ?? ImagePicker();

  final String patientId;
  final ParamedicoIncidentsRepository _detailRepo;
  final PatientsRepository _patientsRepo;
  final ImagePicker _picker;

  ParamedicoPatientDetail? detail;
  String? consultationCode;
  HospitalRow? assignedHospital;

  Map<String, dynamic> vitalSigns = {};
  List<PatientTriageHistoryEntry> triageHistory = [];
  bool actionBusy = false;

  MedicoPatientDetailsShellMode mode = MedicoPatientDetailsShellMode.loading;
  String? errorMessage;

  /// Controla la habilitación de edición en secciones del formulario
  bool clinicalLayoutUnlocked = false;
  bool isEditingPersonalSub = false;

  bool savingClinical = false;
  bool lifecycleStatusSaving = false;

  String editName = '';
  MedicoTriageCategory? editTriageSel;
  List<String> editPhotos = [];

  String editBirthDay = '';
  String editBirthMonth = '';
  String editBirthYear = '';
  MedicoPatientGender? editGender;
  String editContact = '';
  MedicoInsuranceOption? editInsurance;

  String editDescription = '';
  String editSystolic = '';
  String editDiastolic = '';
  String editHeart = '';
  String editRespiratory = '';
  String editTemperature = '';
  String editOxygen = '';
  String editGlucose = '';
  String editAllergies = '';
  String editMedications = '';
  String editMedicalHistory = '';

  MedicoPatientDetailsShellMode get shellMode => mode;

  bool get allowsClinicalEdit {
    final s = detail?.status;
    return s == 'recibido' || s == 'alta_medica';
  }

  Future<void> load() async {
    if (!SupabaseEnv.isConfigured) {
      mode = MedicoPatientDetailsShellMode.error;
      errorMessage = 'Supabase no configurado.';
      notifyListeners();
      return;
    }
    mode = MedicoPatientDetailsShellMode.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final d = await _detailRepo.getPatientDetail(patientId);
      if (d == null) {
        mode = MedicoPatientDetailsShellMode.notFound;
        notifyListeners();
        return;
      }
      HospitalRow? hosp;
      if (d.hospitalId != null && d.hospitalId!.isNotEmpty) {
        hosp = await _detailRepo.getHospitalById(d.hospitalId!);
      }
      final vitals = await _patientsRepo.fetchVitalSigns(patientId);
      final history = await _patientsRepo.fetchTriageHistory(patientId);
      final code = await _detailRepo.getActiveConsultationCode(patientId);
      detail = d;
      consultationCode = code;
      assignedHospital = hosp;
      vitalSigns = vitals;
      triageHistory = history;
      clinicalLayoutUnlocked = false;
      isEditingPersonalSub = false;
      _syncEditorsFromDetail();
      mode = MedicoPatientDetailsShellMode.ready;
      notifyListeners();
    } catch (e) {
      mode = MedicoPatientDetailsShellMode.error;
      errorMessage = '$e';
      notifyListeners();
    }
  }

  bool get showAcceptReject {
    final s = detail?.status;
    return s == 'trasladando';
  }

  bool get showSaveBar =>
      allowsClinicalEdit && clinicalLayoutUnlocked && !showAcceptReject;

  void toggleClinicalPrivileges(BuildContext context) {
    if (!allowsClinicalEdit) {
      showAppSnackBar(
        context,
        'El expediente se puede editar cuando el paciente está «Recibido» o dado '
        'de alta médica (tras el ingreso formal). Si aún viene en traslado, '
        'confirme el ingreso o cancele desde Inicio o con los botones inferiores de '
        'este expediente.',
        isError: true,
      );
      return;
    }
    clinicalLayoutUnlocked = !clinicalLayoutUnlocked;
    if (!clinicalLayoutUnlocked) {
      isEditingPersonalSub = false;
      _syncEditorsFromDetail();
    } else {
      _syncEditorsFromDetail();
      editPhotos
        ..clear()
        ..addAll(photosForUi());
    }
    notifyListeners();
  }

  void togglePersonalSubEdit() {
    if (!clinicalLayoutUnlocked) return;
    isEditingPersonalSub = !isEditingPersonalSub;
    notifyListeners();
  }

  /// Permite la edición de la selección de triage cuando el expediente está desbloqueado
  bool triageBoxesEnabled() => clinicalLayoutUnlocked;

  bool personalSectionReadOnly() =>
      !clinicalLayoutUnlocked || !isEditingPersonalSub;

  void cancelClinicalSession() {
    if (!clinicalLayoutUnlocked) return;
    clinicalLayoutUnlocked = false;
    isEditingPersonalSub = false;
    _syncEditorsFromDetail();
    notifyListeners();
  }

  Future<void> saveClinical(BuildContext context) async {
    if (!allowsClinicalEdit || !clinicalLayoutUnlocked || detail == null) {
      return;
    }
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return;
    }
    if (editTriageSel == null) {
      showAppSnackBar(
        context,
        'Seleccione una clasificación hospitalaria.',
        isError: true,
      );
      return;
    }
    savingClinical = true;
    notifyListeners();
    try {
      final d = detail!;
      final demo = Map<String, dynamic>.from(d.demographics);
      demo['description'] = editDescription.trim();
      demo['gender'] = editGender?.name;
      demo['birth_day'] = _parseTinyInt(editBirthDay);
      demo['birth_month'] = _parseTinyInt(editBirthMonth);
      demo['birth_year'] = _parseTinyInt(editBirthYear);
      demo['emergency_contact'] = editContact.trim().isEmpty
          ? null
          : editContact.trim();

      final ins = editInsurance;
      if (ins != null) {
        demo['seguro_medico'] = ins == MedicoInsuranceOption.si ? 'si' : 'no';
      } else {
        demo.remove('seguro_medico');
      }

      demo['allergies'] = editAllergies.trim().isEmpty
          ? null
          : editAllergies.trim();
      demo['medications'] = editMedications.trim().isEmpty
          ? null
          : editMedications.trim();
      demo['medical_history'] = editMedicalHistory.trim().isEmpty
          ? null
          : editMedicalHistory.trim();

      demo['photo_local_paths'] = List<String>.from(editPhotos);

      final vitMerged = Map<String, dynamic>.from(vitalSigns);
      _putVit(vitMerged, 'systolic_pressure', editSystolic);
      _putVit(vitMerged, 'diastolic_pressure', editDiastolic);
      _putVit(vitMerged, 'heart_rate', editHeart);
      _putVit(vitMerged, 'respiratory_rate', editRespiratory);
      _putVit(vitMerged, 'temperature', editTemperature);
      _putVit(vitMerged, 'oxygen_saturation', editOxygen);
      _putVit(vitMerged, 'glucose', editGlucose);

      await _detailRepo.updatePatientRecord(
        patientId: d.id,
        displayName: editName.trim().isEmpty ? d.displayName : editName.trim(),
        triageColor: _sqlTriage(editTriageSel!),
        demographics: demo,
      );
      await _patientsRepo.updateVitalSigns(patientId: d.id, vitals: vitMerged);

      vitalSigns = vitMerged;

      if (!context.mounted) return;
      showAppSnackBar(context, 'Expediente actualizado.');
      clinicalLayoutUnlocked = false;
      isEditingPersonalSub = false;
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      savingClinical = false;
      notifyListeners();
    }
  }

  Future<void> pickPatientPhoto(ImageSource src) async {
    if (!allowsClinicalEdit || !clinicalLayoutUnlocked) return;
    try {
      final img = await _picker.pickImage(source: src, imageQuality: 80);
      if (img != null) {
        editPhotos.add(img.path);
        notifyListeners();
      }
    } catch (_) {}
  }

  void removePhotoAt(int i) {
    if (!clinicalLayoutUnlocked || i < 0 || i >= editPhotos.length) {
      return;
    }
    editPhotos.removeAt(i);
    notifyListeners();
  }

  void onTriageCategorySelected(MedicoTriageCategory c) {
    editTriageSel = c;
    notifyListeners();
  }

  void setEditGender(MedicoPatientGender? g) {
    editGender = g;
    notifyListeners();
  }

  void setEditInsurance(MedicoInsuranceOption? i) {
    editInsurance = i;
    notifyListeners();
  }

  void setEditName(String v) {
    editName = v;
  }

  void setEditBirthDay(String v) {
    editBirthDay = v;
    notifyListeners();
  }

  void setEditBirthMonth(String v) {
    editBirthMonth = v;
    notifyListeners();
  }

  void setEditBirthYear(String v) {
    editBirthYear = v;
    notifyListeners();
  }

  void setEditContact(String v) {
    editContact = v;
    notifyListeners();
  }

  void setEditDescription(String v) {
    editDescription = v;
    notifyListeners();
  }

  void setEditSystolic(String v) {
    editSystolic = v;
    notifyListeners();
  }

  void setEditDiastolic(String v) {
    editDiastolic = v;
    notifyListeners();
  }

  void setEditHeart(String v) {
    editHeart = v;
    notifyListeners();
  }

  void setEditRespiratory(String v) {
    editRespiratory = v;
    notifyListeners();
  }

  void setEditTemperature(String v) {
    editTemperature = v;
    notifyListeners();
  }

  void setEditOxygen(String v) {
    editOxygen = v;
    notifyListeners();
  }

  void setEditGlucose(String v) {
    editGlucose = v;
    notifyListeners();
  }

  void setEditAllergies(String v) {
    editAllergies = v;
    notifyListeners();
  }

  void setEditMedications(String v) {
    editMedications = v;
    notifyListeners();
  }

  void setEditMedicalHistory(String v) {
    editMedicalHistory = v;
    notifyListeners();
  }

  /// Retorna el día de nacimiento según el modo activo
  String birthDayField(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editBirthDay
      : ((demo['birth_day'] as num?)?.toInt().toString() ?? '');

  String birthMonthField(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editBirthMonth
      : ((demo['birth_month'] as num?)?.toInt().toString() ?? '');

  String birthYearField(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editBirthYear
      : ((demo['birth_year'] as num?)?.toInt().toString() ?? '');

  MedicoPatientGender? genderField(Map<String, dynamic> demo) =>
      clinicalLayoutUnlocked ? editGender : genderUi(demo);

  String contactField(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editContact
      : (demo['emergency_contact'] as String? ?? '');

  MedicoInsuranceOption? insuranceField(Map<String, dynamic> demo) =>
      clinicalLayoutUnlocked ? editInsurance : insuranceUi(demo);

  List<String> photosForToolbar() =>
      clinicalLayoutUnlocked ? editPhotos : photosForUi();

  List<String> photosForUi() {
    final d = detail;
    if (d == null) return [];
    final paths = PatientDemographicsMapper.photoPathsFromDemo(d.demographics);
    return paths.where((p) {
      if (p.startsWith('asset:')) return true;
      try {
        return File(p).existsSync();
      } catch (_) {
        return false;
      }
    }).toList();
  }

  MedicoTriageCategory triageUi() {
    final raw = detail?.triageColor ?? 'amarillo';
    switch (raw) {
      case 'rojo':
      case 'negro':
        return MedicoTriageCategory.rojo;
      case 'naranja':
        return MedicoTriageCategory.naranja;
      case 'amarillo':
        return MedicoTriageCategory.amarillo;
      case 'verde':
        return MedicoTriageCategory.verde;
      case 'azul':
        return MedicoTriageCategory.azul;
      default:
        return MedicoTriageCategory.amarillo;
    }
  }

  MedicoPatientStatus medicoLifecycleUi() {
    final raw = detail?.status ?? 'registrado';
    switch (raw) {
      case 'trasladando':
      case 'registrado':
        return MedicoPatientStatus.enCamino;
      case 'en_espera':
        return MedicoPatientStatus.enEspera;
      case 'recibido':
        return MedicoPatientStatus.recibido;
      case 'alta_medica':
        return MedicoPatientStatus.altaMedica;
      default:
        return MedicoPatientStatus.enCamino;
    }
  }

  String _lifecycleStatusSql(MedicoPatientStatus s) {
    switch (s) {
      case MedicoPatientStatus.enCamino:
        return 'trasladando';
      case MedicoPatientStatus.enEspera:
        return 'en_espera';
      case MedicoPatientStatus.recibido:
        return 'recibido';
      case MedicoPatientStatus.altaMedica:
        return 'alta_medica';
    }
  }

  Future<void> applyLifecycleStatusPick(
    BuildContext context,
    MedicoPatientStatus picked,
  ) async {
    if (!allowsClinicalEdit ||
        !clinicalLayoutUnlocked ||
        detail == null ||
        lifecycleStatusSaving) {
      return;
    }
    final nextSql = _lifecycleStatusSql(picked);
    if (detail!.status == nextSql) return;

    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return;
    }

    if (detail!.status == 'recibido' && nextSql == 'alta_medica') {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return MedicoPatientAltaMedicaConfirmDialog(
            onBackTap: () => Navigator.of(ctx).pop(false),
            onConfirmTap: () => Navigator.of(ctx).pop(true),
          );
        },
      );
      if (confirmed != true || !context.mounted) return;
    }

    lifecycleStatusSaving = true;
    notifyListeners();
    try {
      await _patientsRepo.updateLifecycleStatus(
        patientId: detail!.id,
        status: nextSql,
      );
      if (!context.mounted) return;
      showAppSnackBar(context, 'Estado del paciente actualizado.');
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      lifecycleStatusSaving = false;
      notifyListeners();
    }
  }

  MedicoPatientGender? genderUi(Map<String, dynamic> demo) {
    final raw = demo['gender'] as String?;
    if (raw == null) return null;
    for (final g in MedicoPatientGender.values) {
      if (g.name == raw) return g;
    }
    return null;
  }

  MedicoInsuranceOption? insuranceUi(Map<String, dynamic> demo) {
    final v =
        demo['seguro_medico'] ?? demo['has_insurance'] ?? demo['insurance'];
    if (v == true) return MedicoInsuranceOption.si;
    if (v == false) return MedicoInsuranceOption.no;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'si' || s == 'sí' || s == 'true') {
        return MedicoInsuranceOption.si;
      }
      if (s == 'no' || s == 'false') return MedicoInsuranceOption.no;
    }
    return null;
  }

  String? _vitStr(String k1, String k2, Map<String, dynamic> demo) {
    final vs = vitalSigns;
    for (final k in [k1, k2]) {
      final v = vs[k] ?? demo[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  String descriptionUi(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editDescription
      : (demo['description'] as String?)?.trim() ?? '';

  void onBack(BuildContext context) {
    context.pop();
  }

  Future<void> onAccept(BuildContext context) async {
    if (detail == null || actionBusy) return;
    actionBusy = true;
    notifyListeners();
    try {
      final ok = await MedicoIncomingTransferInteractions.acceptIncoming(
        context: context,
        patientId: detail!.id,
        repository: _patientsRepo,
      );
      if (ok && context.mounted) context.pop(true);
    } finally {
      actionBusy = false;
      notifyListeners();
    }
  }

  Future<void> onRejectFlow(BuildContext context) async {
    if (detail == null || actionBusy) return;

    actionBusy = true;
    notifyListeners();
    try {
      final ok =
          await MedicoIncomingTransferInteractions.rejectIncomingTransfer(
            context: context,
            patientId: detail!.id,
            repository: _patientsRepo,
          );
      if (ok && context.mounted) context.pop(true);
    } finally {
      actionBusy = false;
      notifyListeners();
    }
  }

  String systolic(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editSystolic
      : (_vitStr('systolic_pressure', 'systolic', demo) ??
            _vitStr('ta_sist', 'tas', demo) ??
            '');

  String diastolic(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editDiastolic
      : (_vitStr('diastolic_pressure', 'diastolic', demo) ??
            _vitStr('ta_diast', 'tad', demo) ??
            '');

  String heart(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editHeart
      : (_vitStr('heart_rate', 'pulso', demo) ??
            _vitStr('fc', 'frec_cardiaca', demo) ??
            '');

  String respiratory(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editRespiratory
      : (_vitStr('respiratory_rate', 'fr_respiratoria', demo) ??
            _vitStr('rpm', 'frec_respiratoria', demo) ??
            '');

  String temperature(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editTemperature
      : (_vitStr('temperature', 'temperatura', demo) ??
            (vitalSigns['temp'] != null ? vitalSigns['temp'].toString() : ''));

  String oxygen(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editOxygen
      : (_vitStr('oxygen_saturation', 'spo2', demo) ??
            (vitalSigns['sat_o2'] != null
                ? vitalSigns['sat_o2'].toString()
                : ''));

  String glucose(Map<String, dynamic> demo) => clinicalLayoutUnlocked
      ? editGlucose
      : (_vitStr('glucose', 'glucosa', demo) ?? '');

  String allergies(Map<String, dynamic> demo) =>
      clinicalLayoutUnlocked ? editAllergies : _allergyLoaded(demo);

  String medications(Map<String, dynamic> demo) =>
      clinicalLayoutUnlocked ? editMedications : _medsLoaded(demo);

  String medicalHistory(Map<String, dynamic> demo) =>
      clinicalLayoutUnlocked ? editMedicalHistory : _histLoaded(demo);

  String _allergyLoaded(Map<String, dynamic> demo) =>
      _vitStr('allergies', 'alergias', demo) ??
      (demo['allergies'] as String?) ??
      '';

  String _medsLoaded(Map<String, dynamic> demo) =>
      _vitStr('medications', 'medicamentos', demo) ??
      (demo['medications'] as String?) ??
      '';

  String _histLoaded(Map<String, dynamic> demo) =>
      _vitStr('medical_history', 'antecedentes', demo) ??
      (demo['medical_history'] as String?) ??
      '';

  void _syncEditorsFromDetail() {
    final d = detail;
    if (d == null) return;
    final demo = d.demographics;
    editName = d.displayName;
    editTriageSel = triageUi();

    editBirthDay = (demo['birth_day'] as num?)?.toInt().toString() ?? '';
    editBirthMonth = (demo['birth_month'] as num?)?.toInt().toString() ?? '';
    editBirthYear = (demo['birth_year'] as num?)?.toInt().toString() ?? '';
    editGender = genderUi(demo);
    editContact = demo['emergency_contact'] as String? ?? '';
    editInsurance = insuranceUi(demo);
    editDescription = (demo['description'] as String?)?.trim() ?? '';

    editSystolic = systolicForSync(demo);
    editDiastolic = diastolicForSync(demo);
    editHeart = heartForSync(demo);
    editRespiratory = respiratoryForSync(demo);
    editTemperature = temperatureForSync(demo);
    editOxygen = oxygenForSync(demo);
    editGlucose = glucoseForSync(demo);
    editAllergies = _allergyLoaded(demo);
    editMedications = _medsLoaded(demo);
    editMedicalHistory = _histLoaded(demo);
  }

  String systolicForSync(Map<String, dynamic> demo) =>
      _vitStr('systolic_pressure', 'systolic', demo) ??
      _vitStr('ta_sist', 'tas', demo) ??
      '';

  String diastolicForSync(Map<String, dynamic> demo) =>
      _vitStr('diastolic_pressure', 'diastolic', demo) ??
      _vitStr('ta_diast', 'tad', demo) ??
      '';

  String heartForSync(Map<String, dynamic> demo) =>
      _vitStr('heart_rate', 'pulso', demo) ??
      _vitStr('fc', 'frec_cardiaca', demo) ??
      '';

  String respiratoryForSync(Map<String, dynamic> demo) =>
      _vitStr('respiratory_rate', 'fr_respiratoria', demo) ??
      _vitStr('rpm', 'frec_respiratoria', demo) ??
      '';

  String temperatureForSync(Map<String, dynamic> demo) =>
      _vitStr('temperature', 'temperatura', demo) ??
      (vitalSigns['temp'] != null ? vitalSigns['temp'].toString() : '');

  String oxygenForSync(Map<String, dynamic> demo) =>
      _vitStr('oxygen_saturation', 'spo2', demo) ??
      (vitalSigns['sat_o2'] != null ? vitalSigns['sat_o2'].toString() : '');

  String glucoseForSync(Map<String, dynamic> demo) =>
      _vitStr('glucose', 'glucosa', demo) ?? '';

  void _putVit(Map<String, dynamic> m, String key, String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      m.remove(key);
    } else {
      m[key] = t;
    }
  }

  int? _parseTinyInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  String _sqlTriage(MedicoTriageCategory c) {
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

  Future<void> onShowConsultationQr(BuildContext context) async {
    try {
      var code = consultationCode;
      if (code == null || code.isEmpty) {
        code = await _detailRepo.ensureConsultationCode(patientId);
        consultationCode = code;
        notifyListeners();
      }
      if (!context.mounted) return;
      await ConsultationCodeQrDialog.show(context, code: code);
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, '$e', isError: true);
      }
    }
  }
}
