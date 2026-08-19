import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_result.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_title_formatter.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_display_name_formatter.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/patient_location_actions.dart';

// Orquestador de registro de paciente: formulario, fotos, QR y persistencia
class PatientRegistrationController extends ChangeNotifier {
  PatientRegistrationController({
    this.incidentId,
    this.seedLatitude,
    this.seedLongitude,
    ParamedicoIncidentsRepository? repository,
    ImagePicker? picker,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       _picker = picker ?? ImagePicker();

  final String? incidentId;
  bool get deferIncidentCreation => incidentId == null;
  final double? seedLatitude;
  final double? seedLongitude;
  final ParamedicoIncidentsRepository _repo;
  final ImagePicker _picker;

  final GlobalKey mapSectionKey = GlobalKey();

  TriageCategory? triageCategory;
  final List<String> photos = [];
  final Set<PatientInjuryType> selectedInjuries = {};
  PatientGender? gender;
  PatientBloodType? bloodType;
  int? birthDay;
  int? birthMonth;
  int? birthYear;
  String contactNumber = '';
  String description = '';
  String displayName = '';
  bool submitting = false;
  String lastQuerySig = '';
  double patientLat = 32.5027;
  double patientLng = -117.00371;
  bool patientCoordsLoading = true;

  String get gpsCoordinatesLabel => patientCoordsLoading
      ? '…'
      : '${patientLat.toStringAsFixed(5)}, ${patientLng.toStringAsFixed(5)}';

  void init() {
    final sl = seedLatitude;
    final sw = seedLongitude;
    if (sl != null && sw != null) {
      patientLat = sl;
      patientLng = sw;
      patientCoordsLoading = false;
      notifyListeners();
      if (deferIncidentCreation) return;
    }
    if (deferIncidentCreation) {
      unawaited(_seedFromDevice());
      return;
    }
    unawaited(_seedPatientLocationFromIncident());
  }

  Future<void> _seedFromDevice() async {
    if (!SupabaseEnv.isConfigured) {
      patientCoordsLoading = false;
      notifyListeners();
      return;
    }
    try {
      final pos = await IncidentLocationService.getCurrentPosition();
      if (pos != null) {
        patientLat = pos.lat;
        patientLng = pos.lng;
      }
    } catch (_) {
      // keep defaults
    } finally {
      patientCoordsLoading = false;
      notifyListeners();
    }
  }

  Future<String> _ensureIncidentId() async {
    final existing = incidentId;
    if (existing != null) return existing;
    final title = await IncidentTitleFormatter.resolveTitle(
      customTitle: null,
      atLocal: DateTime.now(),
      lat: patientLat,
      lng: patientLng,
    );
    final typeId = EmergencyCatalog.defaultTypeId;
    return _repo.createIncident(
      title: title,
      emergencyType: typeId == 'OTRO' ? 'otro' : typeId,
      lat: patientLat,
      lng: patientLng,
    );
  }

  Future<void> _seedPatientLocationFromIncident() async {
    if (!SupabaseEnv.isConfigured) {
      patientCoordsLoading = false;
      notifyListeners();
      return;
    }
    try {
      final inc = await _repo.getIncident(incidentId!);
      if (inc?.latitude != null && inc?.longitude != null) {
        patientLat = inc!.latitude!;
        patientLng = inc.longitude!;
      }
    } catch (_) {
      // keep defaults
    } finally {
      patientCoordsLoading = false;
      notifyListeners();
    }
  }

  void applyQueryParamsIfChanged(BuildContext context) {
    final q = GoRouterState.of(context).uri.queryParameters;
    final sig = '${q['triage'] ?? ''}|||${q['displayName'] ?? ''}';
    if (sig == lastQuerySig) return;
    lastQuerySig = sig;
    final t = q['triage'];
    final dn = q['displayName'];
    if (t != null && t.isNotEmpty) {
      for (final c in TriageCategory.values) {
        if (c != TriageCategory.todos && c.sqlValue == t) {
          triageCategory = c;
          break;
        }
      }
    }
    if (dn != null && dn.isNotEmpty) {
      displayName = dn;
    }
    notifyListeners();
  }

  void setTriageCategory(TriageCategory category) {
    triageCategory = category;
    notifyListeners();
  }

  void setDisplayName(String v) {
    displayName = v;
    notifyListeners();
  }

  void setGender(PatientGender? g) {
    gender = g;
    notifyListeners();
  }

  void setBloodType(PatientBloodType? b) {
    bloodType = b;
    notifyListeners();
  }

  void setBirthDay(String value) {
    birthDay = int.tryParse(value);
    notifyListeners();
  }

  void setBirthMonth(String value) {
    birthMonth = int.tryParse(value);
    notifyListeners();
  }

  void setBirthYear(String value) {
    birthYear = int.tryParse(value);
    notifyListeners();
  }

  void setContactNumber(String value) {
    contactNumber = value;
    notifyListeners();
  }

  void setDescription(String text) {
    description = text;
    notifyListeners();
  }

  void toggleInjury(PatientInjuryType injury) {
    final wasSelected = selectedInjuries.contains(injury);
    description = _descriptionWithToggledInjury(
      currentDescription: description,
      injury: injury,
      shouldAdd: !wasSelected,
    );

    if (wasSelected) {
      selectedInjuries.remove(injury);
    } else {
      selectedInjuries.add(injury);
    }
    notifyListeners();
  }

  String _descriptionWithToggledInjury({
    required String currentDescription,
    required PatientInjuryType injury,
    required bool shouldAdd,
  }) {
    final label = injury.label.trim();
    final segments = _descriptionSegments(
      currentDescription,
    ).where((segment) => !_matchesInjuryLabel(segment, label)).toList();

    if (shouldAdd) segments.add(label);
    return segments.join(', ');
  }

  List<String> _descriptionSegments(String value) {
    final normalized = value.trim().replaceFirst(
      RegExp(r'^Lesiones observadas:\s*'),
      '',
    );
    if (normalized.isEmpty) return [];

    return normalized
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  bool _matchesInjuryLabel(String segment, String label) {
    final normalizedSegment = segment
        .trim()
        .replaceFirst(RegExp(r'[.;]+$'), '')
        .toLowerCase();
    return normalizedSegment == label.toLowerCase();
  }

  void removePhotoAt(int index) {
    photos.removeAt(index);
    notifyListeners();
  }

  Future<void> openMapPreview(BuildContext context) async {
    await IncidentLocationMapDialog.showPreview(
      context,
      lat: patientLat,
      lng: patientLng,
      title: 'Ubicación del paciente',
    );
  }

  Future<void> openPatientLocationPicker(BuildContext context) async {
    final result = await PatientLocationActions.pickInAppMap(
      context,
      lat: patientLat,
      lng: patientLng,
    );
    if (result == null) return;
    patientLat = result.latitude;
    patientLng = result.longitude;
    notifyListeners();
  }

  Future<void> openGoogleMaps(BuildContext context) async {
    await PatientLocationActions.openGoogleMaps(
      context,
      lat: patientLat,
      lng: patientLng,
    );
  }

  Future<void> triangulateLocation(BuildContext context) async {
    final pos = await PatientLocationActions.captureCurrentPosition(context);
    if (pos == null) return;
    patientLat = pos.latitude;
    patientLng = pos.longitude;
    notifyListeners();
  }

  void showQrUnavailableMessage(BuildContext context) {
    showAppSnackBar(
      context,
      'Primero registra al paciente. Después podrás abrir su detalle y generar el código QR.',
    );
  }

  Future<void> showRegisteredConsultationQr(
    BuildContext context,
    String code,
  ) async {
    await ConsultationCodeQrDialog.show(
      context,
      code: code,
      title: 'Paciente registrado',
      confirmLabel: 'Ir al incidente',
    );
  }

  void dismissRootDialogIfOpen(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        photos.add(image.path);
        notifyListeners();
      }
    } catch (_) {}
  }

  void showImageSourceDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFCE1125)),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.pop(ctx);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFCE1125),
                ),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> submit(BuildContext context) async {
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return;
    }
    if (triageCategory == null) {
      showAppSnackBar(
        context,
        'Seleccione la clasificación START.',
        isError: true,
      );
      return;
    }
    submitting = true;
    notifyListeners();
    try {
      final effectiveIncidentId = await _ensureIncidentId();
      final existingCount = await _repo.countPatientsForIncident(
        effectiveIncidentId,
      );
      final resolvedName = await PatientDisplayNameFormatter.resolveDisplayName(
        customName: displayName.trim().isEmpty ? null : displayName.trim(),
        patientNumber: existingCount + 1,
        atLocal: DateTime.now(),
        lat: patientLat,
        lng: patientLng,
      );
      final demographics = <String, dynamic>{
        'injury_types': selectedInjuries.map((e) => e.name).toList(),
        'description': description,
        'gender': gender?.name,
        'blood_type': bloodType?.name,
        if (birthDay != null) 'birth_day': birthDay,
        if (birthMonth != null) 'birth_month': birthMonth,
        if (birthYear != null) 'birth_year': birthYear,
        if (contactNumber.trim().isNotEmpty)
          'emergency_contact': contactNumber.trim(),
        'photo_local_paths': List<String>.from(photos),
      };
      final code = await _repo.registerPatientFull(
        incidentId: effectiveIncidentId,
        triageColor: triageCategory!.sqlValue,
        displayName: resolvedName,
        demographics: demographics,
        locationLat: patientLat,
        locationLng: patientLng,
      );
      submitting = false;
      notifyListeners();
      if (!context.mounted) return;
      try {
        await showRegisteredConsultationQr(context, code);
      } catch (e) {
        if (!context.mounted) return;
        dismissRootDialogIfOpen(context);
        showAppSnackBar(
          context,
          'Paciente registrado. No se pudo mostrar el QR: $e',
          isError: true,
        );
      }
      if (!context.mounted) return;
      if (deferIncidentCreation) {
        context.go('/paramedico/incident/$effectiveIncidentId');
        return;
      }
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/paramedico/incident/$effectiveIncidentId');
      }
    } catch (e) {
      dismissRootDialogIfOpen(context);
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  void goBack(BuildContext context) {
    if (deferIncidentCreation) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/paramedico/paciente');
      }
      return;
    }
    context.go('/paramedico/incident/$incidentId');
  }

  void goHome(BuildContext context) {
    if (deferIncidentCreation) {
      context.go('/paramedico/paciente');
      return;
    }
    context.go('/paramedico/home');
  }

  Future<void> openGuidedProtocol(BuildContext context) async {
    if (deferIncidentCreation) {
      final result = await pushParamedicoFullScreen<StartTriageResult>(
        context,
        '/paramedico/registro-rapido/triage?tab=protocolo',
      );
      if (result == null) return;
      triageCategory = result.triage;
      final name = result.displayName;
      if (name != null && name.isNotEmpty) {
        displayName = name;
      }
      notifyListeners();
      return;
    }
    await pushParamedicoFullScreen(
      context,
      '/paramedico/incident/$incidentId/triage?tab=protocolo',
    );
  }
}
