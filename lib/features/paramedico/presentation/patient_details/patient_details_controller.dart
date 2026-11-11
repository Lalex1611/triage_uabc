import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_demographics_mapper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/patient_location_actions.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/transfer_flow/transfer_folio_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/transfer_flow/transfer_insurance_question_dialog_widget.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

enum PatientDetailsShellMode { loading, error, notFound, ready }

// Orquestador de detalle de paciente: carga, edición, traslado y navegación
class PatientDetailsController extends ChangeNotifier {
  PatientDetailsController({
    required this.patientId,
    ParamedicoIncidentsRepository? repository,
    ImagePicker? picker,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       _picker = picker ?? ImagePicker();

  final String patientId;
  final ParamedicoIncidentsRepository _repo;
  final ImagePicker _picker;

  ParamedicoPatientDetail? detail;
  String? consultationCode;
  ParamedicoIncidentSummary? incident;
  HospitalRow? assignedHospital;
  List<HospitalRow> hospitals = [];
  String? creatorName;
  bool loading = true;
  String? error;
  bool wizardBusy = false;
  bool isEditing = false;
  bool savingEdit = false;
  String editName = '';
  TriageCategory editTriage = TriageCategory.amarillo;
  Set<PatientInjuryType> editInjuries = {};
  String editDescription = '';
  PatientGender? editGender;
  PatientBloodType? editBlood;
  double editLat = 32.5027;
  double editLng = -117.00371;
  int? editBirthDay;
  int? editBirthMonth;
  int? editBirthYear;
  String? editContact;
  final List<String> editPhotos = [];

  PatientDetailsShellMode get shellMode {
    if (loading) return PatientDetailsShellMode.loading;
    if (error != null) return PatientDetailsShellMode.error;
    if (detail == null) return PatientDetailsShellMode.notFound;
    return PatientDetailsShellMode.ready;
  }

  Future<void> load() async {
    if (!SupabaseEnv.isConfigured) {
      loading = false;
      error = 'Supabase no configurado.';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      final d = await _repo.getPatientDetail(patientId);
      ParamedicoIncidentSummary? inc;
      if (d != null && d.incidentId.isNotEmpty) {
        inc = await _repo.getIncident(d.incidentId);
      }
      HospitalRow? hosp;
      if (d?.hospitalId != null) {
        hosp = await _repo.getHospitalById(d!.hospitalId!);
      }
      String? creator;
      if (d != null && d.createdBy.isNotEmpty) {
        creator = await _repo.getProfileFullName(d.createdBy);
      }
      final hlist = await _repo.listActiveHospitals();
      String? code;
      if (d != null) {
        code = await _repo.getActiveConsultationCode(patientId);
      }
      detail = d;
      consultationCode = code;
      incident = inc;
      assignedHospital = hosp;
      creatorName = creator;
      hospitals = hlist;
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  void _hydrateEditFromDetail(ParamedicoPatientDetail d) {
    final demo = d.demographics;
    final coords = patientMapCoords(d);
    editName = d.displayName;
    editTriage = ParamedicoCatalogMappers.triageFromDb(d.triageColor);
    editInjuries = PatientDemographicsMapper.injuriesFromDemo(demo);
    editDescription = demo['description'] as String? ?? '';
    editGender = PatientDemographicsMapper.genderFromDemo(
      demo['gender'] as String?,
    );
    editBlood = PatientDemographicsMapper.bloodFromDemo(
      demo['blood_type'] as String?,
    );
    editLat = coords.$1;
    editLng = coords.$2;
    editBirthDay = (demo['birth_day'] as num?)?.toInt();
    editBirthMonth = (demo['birth_month'] as num?)?.toInt();
    editBirthYear = (demo['birth_year'] as num?)?.toInt();
    editContact = demo['emergency_contact'] as String?;
    editPhotos
      ..clear()
      ..addAll(PatientDemographicsMapper.photoPathsFromDemo(demo));
  }

  void startEdit() {
    final d = detail;
    if (d == null) return;
    _hydrateEditFromDetail(d);
    isEditing = true;
    notifyListeners();
  }

  void cancelEdit() {
    isEditing = false;
    notifyListeners();
  }

  void setEditName(String v) {
    editName = v;
    notifyListeners();
  }

  void setEditTriage(TriageCategory c) {
    editTriage = c;
    notifyListeners();
  }

  void toggleEditInjury(PatientInjuryType injury) {
    final wasSelected = editInjuries.contains(injury);
    editDescription = _descriptionWithToggledInjury(
      currentDescription: editDescription,
      injury: injury,
      shouldAdd: !wasSelected,
    );

    if (wasSelected) {
      editInjuries.remove(injury);
    } else {
      editInjuries.add(injury);
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

  void setEditDescription(String text) {
    editDescription = text;
    notifyListeners();
  }

  void setEditGender(PatientGender? g) {
    editGender = g;
    notifyListeners();
  }

  void setEditBlood(PatientBloodType? b) {
    editBlood = b;
    notifyListeners();
  }

  void setEditBirthDay(int? v) {
    editBirthDay = v;
    notifyListeners();
  }

  void setEditBirthMonth(int? v) {
    editBirthMonth = v;
    notifyListeners();
  }

  void setEditBirthYear(int? v) {
    editBirthYear = v;
    notifyListeners();
  }

  void setEditContact(String? v) {
    editContact = v;
    notifyListeners();
  }

  void setEditCoords(double lat, double lng) {
    editLat = lat;
    editLng = lng;
    notifyListeners();
  }

  Future<void> saveEdit(BuildContext context) async {
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return;
    }
    savingEdit = true;
    notifyListeners();
    try {
      final d = detail!;
      final demo = Map<String, dynamic>.from(d.demographics);
      demo['injury_types'] = editInjuries.map((e) => e.name).toList();
      demo['description'] = editDescription;
      demo['gender'] = editGender?.name;
      demo['blood_type'] = editBlood?.name;
      demo['birth_day'] = editBirthDay;
      demo['birth_month'] = editBirthMonth;
      demo['birth_year'] = editBirthYear;
      demo['emergency_contact'] = editContact;
      demo['photo_local_paths'] = List<String>.from(editPhotos);
      demo['registration_lat'] = editLat;
      demo['registration_lng'] = editLng;

      await _repo.updatePatientRecord(
        patientId: patientId,
        displayName: editName.trim(),
        triageColor: editTriage.sqlValue,
        demographics: demo,
        locationLat: editLat,
        locationLng: editLng,
      );
      if (!context.mounted) return;
      isEditing = false;
      showAppSnackBar(context, 'Datos actualizados.');
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      savingEdit = false;
      notifyListeners();
    }
  }

  (double lat, double lng) patientMapCoords(ParamedicoPatientDetail d) {
    if (isEditing) return (editLat, editLng);
    return PatientDemographicsMapper.detailMapCoords(
      detail: d,
      incident: incident,
      assignedHospital: assignedHospital,
    );
  }

  String gpsLabel(ParamedicoPatientDetail d) {
    if (isEditing) {
      return '${editLat.toStringAsFixed(5)}, ${editLng.toStringAsFixed(5)}';
    }
    return PatientDemographicsMapper.gpsLabel(
      detail: d,
      incident: incident,
      assignedHospital: assignedHospital,
    );
  }

  bool canShowMap(ParamedicoPatientDetail d) =>
      PatientDemographicsMapper.canShowMap(
        detail: d,
        incident: incident,
        assignedHospital: assignedHospital,
      );

  Future<void> openMapPreview(BuildContext context) async {
    final d = detail;
    if (d == null) return;
    final coords = patientMapCoords(d);
    if (!canShowMap(d)) {
      showAppSnackBar(context, 'Sin coordenadas para mostrar.', isError: true);
      return;
    }
    await IncidentLocationMapDialog.showPreview(
      context,
      lat: coords.$1,
      lng: coords.$2,
      title: 'Ubicación del paciente',
    );
  }

  Future<void> pickEditImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        editPhotos.add(image.path);
        notifyListeners();
      }
    } catch (_) {}
  }

  void showEditImageSourceDialog(BuildContext context) {
    if (!isEditing) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFCE1125)),
              title: const Text('Tomar foto con la cámara'),
              onTap: () {
                Navigator.pop(ctx);
                pickEditImage(ImageSource.camera);
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
                pickEditImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void removeEditPhotoAt(int index) {
    if (index < 0 || index >= editPhotos.length) return;
    editPhotos.removeAt(index);
    notifyListeners();
  }

  List<String> photoPathsForUi(ParamedicoPatientDetail d) {
    if (isEditing) return List<String>.from(editPhotos);
    return PatientDemographicsMapper.photoPathsFromDemo(d.demographics);
  }

  /// Botón «Mapas» del widget: picker al editar, mapa interactivo al consultar
  Future<void> openMapFromSection(BuildContext context) async {
    if (isEditing) {
      await openAppMapPicker(context);
    } else {
      openInteractiveMap(context);
    }
  }

  void openInteractiveMap(BuildContext context) {
    final d = detail;
    final inc = incident;
    if (d == null) return;
    if (inc == null || inc.latitude == null || inc.longitude == null) {
      showAppSnackBar(
        context,
        'El incidente no tiene coordenadas en el mapa interactivo.',
        isError: true,
      );
      return;
    }
    final returnTo = Uri.encodeComponent('/paramedico/patient/$patientId');
    pushParamedicoFullScreen(
      context,
      '/paramedico/mapa-interactivo?focus=${inc.id}&focusPatient=$patientId&returnTo=$returnTo',
    );
  }

  Future<void> openAppMapPicker(BuildContext context) async {
    final d = detail;
    if (d == null) return;
    final coords = isEditing ? (editLat, editLng) : patientMapCoords(d);
    final r = await PatientLocationActions.pickInAppMap(
      context,
      lat: coords.$1,
      lng: coords.$2,
    );
    if (r == null || !context.mounted) return;
    await _applyPickedCoords(context, r.latitude, r.longitude);
  }

  Future<void> openGoogleMapsForPatient(BuildContext context) async {
    final d = detail;
    if (d == null) return;
    final coords = patientMapCoords(d);
    await PatientLocationActions.openGoogleMaps(
      context,
      lat: coords.$1,
      lng: coords.$2,
    );
  }

  Future<void> triangulatePatientLocation(BuildContext context) async {
    final pos = await PatientLocationActions.captureCurrentPosition(context);
    if (pos == null || !context.mounted) return;
    await _applyPickedCoords(context, pos.latitude, pos.longitude);
  }

  Future<void> _applyPickedCoords(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    final d = detail;
    if (d == null) return;
    if (isEditing) {
      setEditCoords(lat, lng);
      return;
    }
    try {
      final demo = Map<String, dynamic>.from(d.demographics)
        ..['registration_lat'] = lat
        ..['registration_lng'] = lng;
      await _repo.updatePatientRecord(
        patientId: patientId,
        demographics: demo,
        locationLat: lat,
        locationLng: lng,
      );
      if (!context.mounted) return;
      showAppSnackBar(context, 'Ubicación actualizada.');
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  Future<void> openEditLocation(BuildContext context) async {
    final d = detail;
    if (d == null) return;
    final coords = patientMapCoords(d);
    final r = await PatientLocationActions.pickInAppMap(
      context,
      lat: coords.$1,
      lng: coords.$2,
    );
    if (r == null || !context.mounted) return;
    await _applyPickedCoords(context, r.latitude, r.longitude);
  }

  Future<void> exportRoute(BuildContext context) async {
    final d = detail;
    final h = assignedHospital;
    if (d?.latitude == null ||
        d?.longitude == null ||
        h?.latitude == null ||
        h?.longitude == null) {
      showAppSnackBar(
        context,
        'Faltan coordenadas del paciente u hospital.',
        isError: true,
      );
      return;
    }
    final u = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${d!.latitude},${d.longitude}&destination=${h!.latitude},${h.longitude}&travelmode=driving',
    );
    final can = await canLaunchUrl(u);
    if (!context.mounted) return;
    if (can) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    } else {
      showAppSnackBar(context, 'No se pudo abrir Google Maps.', isError: true);
    }
  }

  List<PopupMenuEntry<PatientStatus>>? statusMenuEntries(String sqlStatus) {
    switch (sqlStatus) {
      case 'en_espera':
        return const [
          PopupMenuItem(
            value: PatientStatus.enEspera,
            child: Text('En espera'),
          ),
          PopupMenuItem(
            value: PatientStatus.trasladando,
            child: Text('Trasladando'),
          ),
        ];
      case 'trasladando':
        return const [
          PopupMenuItem(
            value: PatientStatus.trasladando,
            child: Text('Reasignar hospital'),
          ),
        ];
      default:
        return null;
    }
  }

  void onStatusMenuSelection(BuildContext context, PatientStatus s) {
    unawaited(handleStatusPicked(context, s));
  }

  Future<void> handleStatusPicked(BuildContext context, PatientStatus s) async {
    if (wizardBusy) return;
    final d = detail;
    if (d == null) return;
    wizardBusy = true;
    notifyListeners();
    try {
      final currentStatus = ParamedicoCatalogMappers.statusFromDb(d.status);
      if (s == currentStatus && s != PatientStatus.trasladando) return;
      if (s == PatientStatus.enEspera) {
        await _repo.updatePatientRecord(patientId: d.id, status: 'en_espera');
        if (!context.mounted) return;
        showAppSnackBar(context, 'Estado del paciente actualizado.');
        await load();
        return;
      }
      if (s == PatientStatus.enEspera) {
        return;
      }
      if (s == PatientStatus.trasladando) {
        if (!context.mounted) return;
        await runTrasladoWizard(context);
      }
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      wizardBusy = false;
      notifyListeners();
    }
  }

  Future<void> runTrasladoWizard(BuildContext context) async {
    final d = detail;
    if (d == null) return;
    final unitId = await _repo.currentAmbulanceUnitId();
    if (unitId == null || unitId.isEmpty) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Registra el código de tu unidad desde perfil antes de enviar el traslado.',
          isError: true,
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (hospitals.isEmpty) {
      showAppSnackBar(
        context,
        'No hay hospitales activos disponibles para asignar traslado.',
        isError: true,
      );
      return;
    }

    final hasInsurance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TransferInsuranceQuestionDialog(
        onBackTap: () => Navigator.pop(ctx),
        onNoTap: () => Navigator.pop(ctx, false),
        onYesTap: () => Navigator.pop(ctx, true),
      ),
    );
    if (!context.mounted || hasInsurance == null) return;

    final pickedHospital = await showDialog<HospitalRow>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480, maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFCE1125),
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Hospital de destino',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: hospitals.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final h = hospitals[i];
                      return ListTile(
                        title: Text(h.name),
                        subtitle: h.address != null && h.address!.isNotEmpty
                            ? Text(
                                h.address!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : (h.latitude == null
                                  ? const Text(
                                      'Sin coordenadas en base de datos — complétalas en Supabase.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                      ),
                                    )
                                  : null),
                        onTap: () => Navigator.pop(ctx, h),
                      );
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted || pickedHospital == null) return;

    final folio = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TransferFolioDialog(
        onBackTap: () => Navigator.pop(ctx),
        onSubmit: (s) => Navigator.pop(ctx, s),
      ),
    );
    if (!context.mounted || folio == null) return;

    await _repo.applyPatientTransfer(
      patientId: d.id,
      newStatus: 'trasladando',
      hospitalId: pickedHospital.id,
      regulationFolio: folio.trim().isEmpty ? null : folio.trim(),
      demographicsExtras: {
        'has_medical_insurance': hasInsurance,
        'transfer_destination_hospital_name': pickedHospital.name,
      },
      patientLocationLat: pickedHospital.latitude,
      patientLocationLng: pickedHospital.longitude,
    );
    if (!context.mounted) return;
    await load();
    if (!context.mounted) return;
    await _showEmergencyHospitalAssignedDialog(context, pickedHospital.name);
  }

  Future<void> _showEmergencyHospitalAssignedDialog(
    BuildContext context,
    String hospitalName,
  ) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2CA24D), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hospital de emergencia asignado: "$hospitalName"',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void onBack(BuildContext context) {
    final d = detail;
    if (d == null) return;
    if (isEditing) {
      cancelEdit();
      return;
    }
    if (d.incidentId.isNotEmpty) {
      context.go('/paramedico/incident/${d.incidentId}');
    } else {
      context.pop();
    }
  }

  Future<void> confirmClosePatient(BuildContext context) async {
    final d = detail;
    if (d == null) return;
    if (isEditing) {
      showAppSnackBar(
        context,
        'Guarde o cancele la edición antes de cerrar el paciente.',
        isError: true,
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar paciente'),
        content: const Text('¿Cerrar el registro actual de este paciente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await _repo.updatePatientRecord(patientId: d.id, status: 'alta_medica');
      if (!context.mounted) return;
      showAppSnackBar(context, 'Paciente cerrado.');
      if (d.incidentId.isNotEmpty) {
        context.go('/paramedico/incident/${d.incidentId}');
      } else {
        context.go('/paramedico/paciente');
      }
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, '$e', isError: true);
    }
  }

  Future<void> onGenerateQrTap(BuildContext context) async {
    try {
      var code = consultationCode;
      if (code == null || code.isEmpty) {
        code = await _repo.ensureConsultationCode(patientId);
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

  String patientIdLabel(ParamedicoPatientDetail d) =>
      IncidentPresentationFormatters.shortPatientId(d.id);

  bool showExportRoute(ParamedicoPatientDetail d) =>
      d.status == 'trasladando' &&
      d.latitude != null &&
      d.longitude != null &&
      assignedHospital?.latitude != null &&
      assignedHospital?.longitude != null;
}
