import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_details_result.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_edit/medico_patient_edit_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_attention_note.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_discharge_info.dart';
import 'package:sistema_triage/features/medico/presentation/discharge/medico_discharge_page.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_attention_note_dialog.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_room_triage_sheet.dart';
import 'package:sistema_triage/features/medico/presentation/patient_edit/medico_patient_edit_page.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_incoming_transfer_interactions.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_demographics_mapper.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';

enum MedicoPatientDetailsShellMode { loading, error, notFound, ready }

/// Lógica de la pantalla de un paciente para el médico: revisión del paciente
/// en camino (02) y vista en sala (06) con sus acciones
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

  /// Resumen del paciente: incidente, unidad, paramédico, fotos, etc. Lo usan
  /// la revisión del paciente en camino (mockup 02) y la vista en sala (06)
  MedicoIncomingReview? summary;

  /// Notas de atención (vista en sala), de la más reciente a la más antigua
  List<MedicoAttentionNote> attentionNotes = [];

  /// Alta registrada (destino y nota); solo si el paciente ya tiene alta
  MedicoDischargeInfo? discharge;

  /// La última lectura de notas / del alta falló (distinto de "no hay");
  /// la vista en sala muestra un aviso con "Reintentar"
  bool attentionNotesLoadFailed = false;
  bool dischargeLoadFailed = false;

  /// Momento en que entró a `recibido` / `alta_medica` (vista en sala)
  DateTime? receivedAt;
  DateTime? dischargedAt;

  /// Guardando un cambio rápido de la vista en sala (p. ej. agregar foto)
  bool roomBusy = false;

  /// Hubo cambios: al salir se avisa a la lista para que se recargue
  bool didChange = false;

  Map<String, dynamic> vitalSigns = {};
  List<PatientTriageHistoryEntry> triageHistory = [];
  bool actionBusy = false;

  MedicoPatientDetailsShellMode mode = MedicoPatientDetailsShellMode.loading;
  String? errorMessage;

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
      final vitals = await _patientsRepo.fetchVitalSigns(patientId);
      final history = await _patientsRepo.fetchTriageHistory(patientId);
      final code = await _detailRepo.getActiveConsultationCode(patientId);
      final inRoomFlow = const {
        'trasladando',
        'recibido',
        'alta_medica',
      }.contains(d.status);
      summary = inRoomFlow
          ? await _patientsRepo.fetchIncomingReview(patientId)
          : null;
      if (d.status == 'recibido' || d.status == 'alta_medica') {
        final t = await _patientsRepo.fetchStatusTimestamps([patientId]);
        receivedAt = t.receivedAt[patientId];
        dischargedAt = t.dischargedAt[patientId];
        await _loadAttentionNotes();
        if (d.status == 'alta_medica') {
          await _loadDischarge();
        } else {
          discharge = null;
          dischargeLoadFailed = false;
        }
      } else {
        discharge = null;
        receivedAt = null;
        dischargedAt = null;
        attentionNotes = [];
        attentionNotesLoadFailed = false;
        dischargeLoadFailed = false;
      }
      detail = d;
      consultationCode = code;
      vitalSigns = vitals;
      triageHistory = history;
      mode = MedicoPatientDetailsShellMode.ready;
      notifyListeners();
    } catch (e) {
      mode = MedicoPatientDetailsShellMode.error;
      errorMessage = '$e';
      notifyListeners();
    }
  }

  /// Vista en sala (mockup 06): paciente recibido o dado de alta
  bool get showRoomView => summary != null && allowsClinicalEdit;

  /// Si las notas no se pueden leer, la vista en sala se muestra igual: se
  /// conservan las que ya se tenían y se marca el fallo para ofrecer reintento
  Future<void> _loadAttentionNotes() async {
    try {
      attentionNotes = await _patientsRepo.fetchAttentionNotes(patientId);
      attentionNotesLoadFailed = false;
    } catch (_) {
      attentionNotesLoadFailed = true;
    }
  }

  /// Igual que las notas: un fallo no se confunde con "sin alta registrada"
  Future<void> _loadDischarge() async {
    try {
      discharge = await _patientsRepo.fetchDischarge(patientId);
      dischargeLoadFailed = false;
    } catch (_) {
      dischargeLoadFailed = true;
    }
  }

  /// "Reintentar" en la vista en sala: vuelve a leer lo que falló
  Future<void> retryRoomRecords() async {
    final d = detail;
    if (d == null || roomBusy) return;
    roomBusy = true;
    notifyListeners();
    try {
      if (attentionNotesLoadFailed) await _loadAttentionNotes();
      if (dischargeLoadFailed && d.status == 'alta_medica') {
        await _loadDischarge();
      }
    } finally {
      roomBusy = false;
      notifyListeners();
    }
  }

  /// "Dar alta médica" (mockup 10): destino y nota de alta
  Future<void> dischargeFromRoom(BuildContext context) async {
    final d = detail;
    if (d == null || d.status != 'recibido' || roomBusy) return;
    final done = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MedicoDischargePage(
          folio: IncidentPresentationFormatters.shortPatientId(d.id),
          patientName: summary?.displayName ?? d.displayName,
          onConfirm: (destination, note) => _patientsRepo.dischargePatient(
            patientId: d.id,
            destination: destination.dbValue,
            note: note,
          ),
        ),
      ),
    );
    if (done != true || !context.mounted) return;
    didChange = true;
    showAppSnackBar(context, 'Alta médica registrada.');
    await load();
  }

  /// Lápiz de la tarjeta de triage (vista en sala): elige el nivel y lo
  /// guarda con la RPC del triage hospitalario
  Future<void> changeTriageFromRoom(BuildContext context) async {
    final d = detail;
    final current = summary?.triage;
    if (d == null || current == null || d.status != 'recibido' || roomBusy) {
      return;
    }
    final picked = await MedicoRoomTriageSheet.show(context, current: current);
    if (picked == null || picked == current || !context.mounted) return;
    await _roomAction(
      context,
      () => _patientsRepo.setHospitalTriage(
        patientId: d.id,
        triageColor: picked.name,
      ),
      'Triage actualizado.',
    );
  }

  /// "Agregar nota de atención": pop-up para escribirla y guardarla
  Future<void> addAttentionNote(BuildContext context) async {
    final d = detail;
    if (d == null || d.status != 'recibido' || roomBusy) return;
    final saved = await MedicoAttentionNoteDialog.show(
      context,
      onSave: (body) =>
          _patientsRepo.addAttentionNote(patientId: d.id, body: body),
    );
    if (!saved) return;
    await _loadAttentionNotes();
    notifyListeners();
    if (context.mounted) showAppSnackBar(context, 'Nota de atención agregada.');
  }

  /// "Editar paciente" (menú ⋯ de la vista en sala): identificación, seguro,
  /// datos adicionales y signos vitales
  Future<void> openEditPatient(BuildContext context) async {
    final d = detail;
    if (d == null || roomBusy) return;
    final initial = MedicoPatientEditData.fromRecord(
      displayName: summary?.displayName ?? d.displayName,
      demographics: d.demographics,
      vitalSigns: vitalSigns,
    );
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MedicoPatientEditPage(
          folio: IncidentPresentationFormatters.shortPatientId(d.id),
          initial: initial,
          onSave: (data) => _patientsRepo.updatePatientInfo(
            patientId: d.id,
            displayName: data.displayName,
            demographics: data.applyToDemographics(d.demographics),
            vitalSigns: data.applyToVitalSigns(vitalSigns),
          ),
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    didChange = true;
    showAppSnackBar(context, 'Datos del paciente actualizados.');
    await load();
  }

  Future<void> _roomAction(
    BuildContext context,
    Future<void> Function() action,
    String okMessage,
  ) async {
    if (roomBusy) return;
    roomBusy = true;
    notifyListeners();
    try {
      await action();
      didChange = true;
      if (!context.mounted) return;
      showAppSnackBar(context, okMessage);
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      roomBusy = false;
      notifyListeners();
    }
  }

  /// Agrega una foto al expediente y la guarda de inmediato
  Future<void> addRoomPhoto(BuildContext context, ImageSource src) async {
    final d = detail;
    if (d == null || !allowsClinicalEdit) return;
    XFile? img;
    try {
      img = await _picker.pickImage(source: src, imageQuality: 80);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'No se pudo abrir la cámara o la galería.',
          isError: true,
        );
      }
      return;
    }
    if (img == null || !context.mounted) return;
    final path = img.path;
    // Se agrega en el servidor sobre la fila actual: no se reescribe
    // demographics con la copia de antes de abrir la cámara (otro médico
    // pudo editar al paciente mientras tanto)
    await _roomAction(
      context,
      () => _patientsRepo.appendPatientPhoto(patientId: d.id, path: path),
      'Foto agregada.',
    );
  }

  bool get showAcceptReject {
    final s = detail?.status;
    return s == 'trasladando';
  }

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

  void onBack(BuildContext context) {
    if (didChange) {
      context.pop(true);
    } else {
      context.pop();
    }
  }

  Future<void> onAccept(BuildContext context) async {
    final review = summary;
    if (detail == null || review == null || actionBusy) return;
    actionBusy = true;
    notifyListeners();
    try {
      final outcome = await MedicoIncomingTransferInteractions.acceptIncoming(
        context: context,
        review: review,
        consultationCode: consultationCode,
        repository: _patientsRepo,
      );
      if (!context.mounted) return;
      switch (outcome) {
        case MedicoAcceptOutcome.notAccepted:
          break;
        case MedicoAcceptOutcome.accepted:
          context.pop(true);
        case MedicoAcceptOutcome.acceptedOpenRoom:
          context.pop(MedicoPatientDetailsResult.openRoom);
      }
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
            patientName: summary?.displayName ?? detail!.displayName,
            repository: _patientsRepo,
          );
      if (ok && context.mounted) context.pop(true);
    } finally {
      actionBusy = false;
      notifyListeners();
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

  /// Una lectura o acción puede terminar después de salir de la ruta; en ese
  /// caso ya no hay a quién avisar
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
