import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/medico_incoming_review_page.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/medico_room_format.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/medico_room_patient_page.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_room_photos_history_widget.dart';
import 'package:sistema_triage/features/medico/presentation/routing/medico_patient_details_controller.dart';

/// Pantalla de un paciente para el médico: revisión si viene en camino
/// (mockup 02) o vista en sala si ya fue recibido o dado de alta (mockup 06)
class MedicoPatientDetailsFlowPage extends StatefulWidget {
  const MedicoPatientDetailsFlowPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<MedicoPatientDetailsFlowPage> createState() =>
      _MedicoPatientDetailsFlowPageState();
}

class _MedicoPatientDetailsFlowPageState
    extends State<MedicoPatientDetailsFlowPage> {
  late final MedicoPatientDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MedicoPatientDetailsController(patientId: widget.patientId);
    _controller.addListener(_onController);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final mode = c.shellMode;

    if (mode != MedicoPatientDetailsShellMode.ready) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text('Detalle del paciente'),
        ),
        body: Center(
          child: switch (mode) {
            MedicoPatientDetailsShellMode.loading =>
              const CircularProgressIndicator(),
            MedicoPatientDetailsShellMode.notFound => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Paciente no encontrado.'),
            ),
            _ => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(c.errorMessage ?? 'Error'),
            ),
          },
        ),
      );
    }

    // Paciente en camino: revisión para aceptar o rechazar (mockup 02)
    final review = c.summary;
    if (c.showAcceptReject && review != null) {
      return MedicoIncomingReviewPage(
        review: review,
        busy: c.actionBusy,
        onBackTap: () => c.onBack(context),
        onAcceptTap: () => unawaited(c.onAccept(context)),
        onRejectTap: () => unawaited(c.onRejectFlow(context)),
      );
    }

    // Paciente recibido o dado de alta: vista en sala (mockup 06)
    if (c.showRoomView) return _roomView(context, c);

    // Cualquier otro estado (p. ej. el traslado se canceló mientras se abría)
    return _unavailable(context, c);
  }

  Widget _roomView(BuildContext context, MedicoPatientDetailsController c) {
    final d = c.detail!;
    final discharged = d.status == 'alta_medica';
    final now = DateTime.now();
    final photos = [...c.summary!.photoUrls, ...c.photosForUi()];
    final history = [
      for (final e in c.triageHistory.take(8))
        MedicoRoomHistoryItem(
          time: MedicoRoomFormat.historyTime(e.changedAt.toLocal(), now),
          event: MedicoRoomFormat.historyEvent(e),
          actor: e.actorRole == null ? null : e.actorRoleLabel,
        ),
    ];

    return MedicoRoomPatientPage(
      summary: c.summary!,
      discharged: discharged,
      receivedAt: c.receivedAt,
      dischargedAt: c.dischargedAt,
      consultationCode: c.consultationCode,
      photos: photos,
      history: history,
      notes: c.attentionNotes,
      notesLoadFailed: c.attentionNotesLoadFailed,
      discharge: c.discharge,
      dischargeLoadFailed: c.dischargeLoadFailed,
      onRetryRecordsTap: () => unawaited(c.retryRoomRecords()),
      busy: c.roomBusy,
      now: now,
      onBackTap: () => c.onBack(context),
      onEditPatientTap: () => unawaited(c.openEditPatient(context)),
      onShowQrTap: () => unawaited(c.onShowConsultationQr(context)),
      onEditTriageTap: discharged
          ? null
          : () => unawaited(c.changeTriageFromRoom(context)),
      onAddPhotoTap: discharged ? null : () => _pickPhotoSource(context, c),
      onAddNoteTap: discharged
          ? null
          : () => unawaited(c.addAttentionNote(context)),
      onDischargeTap: discharged
          ? null
          : () => unawaited(c.dischargeFromRoom(context)),
    );
  }

  Future<void> _pickPhotoSource(
    BuildContext context,
    MedicoPatientDetailsController c,
  ) async {
    final src = await showModalBottomSheet<ImageSource>(
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
    if (src != null && context.mounted) await c.addRoomPhoto(context, src);
  }

  Widget _unavailable(BuildContext context, MedicoPatientDetailsController c) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Detalle del paciente'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este paciente ya no está en camino ni en la sala de su hospital.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
