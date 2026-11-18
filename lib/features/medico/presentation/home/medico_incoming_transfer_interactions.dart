import 'package:flutter/material.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/medico_accept_transfer_page.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/medico_transfer_accepted_page.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/medico_reject_transfer_page.dart';

/// Resultado de aceptar un traslado
enum MedicoAcceptOutcome {
  /// Se canceló en la confirmación (03)
  notAccepted,

  /// Aceptado; "Volver a entrantes" en la confirmación (11)
  accepted,

  /// Aceptado; "Ver en la sala" en la confirmación (11)
  acceptedOpenRoom,
}

/// Recibir o rechazar a un paciente en **trasladando** (Entradas o revisión).
/// Abre las pantallas de los mockups 03 (confirmar recepción), 11 (paciente
/// aceptado) y 04 (rechazar traslado).
class MedicoIncomingTransferInteractions {
  MedicoIncomingTransferInteractions._();

  static Future<MedicoAcceptOutcome> acceptIncoming({
    required BuildContext context,
    required MedicoIncomingReview review,
    String? consultationCode,
    PatientsRepository? repository,
  }) async {
    final repo = repository ?? PatientsRepository();
    final navigator = Navigator.of(context, rootNavigator: true);
    final ok = await navigator.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MedicoAcceptTransferPage(
          review: review,
          onConfirm: () => repo.receivePatient(patientId: review.patientId),
        ),
      ),
    );
    if (ok != true) return MedicoAcceptOutcome.notAccepted;

    // Ya quedó recibido: la confirmación (11) solo decide a dónde ir
    final openRoom = await navigator.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MedicoTransferAcceptedPage(
          review: review,
          consultationCode: consultationCode,
        ),
      ),
    );
    return openRoom == true
        ? MedicoAcceptOutcome.acceptedOpenRoom
        : MedicoAcceptOutcome.accepted;
  }

  static Future<bool> rejectIncomingTransfer({
    required BuildContext context,
    required String patientId,
    required String patientName,
    PatientsRepository? repository,
  }) async {
    final repo = repository ?? PatientsRepository();
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MedicoRejectTransferPage(
          patientId: patientId,
          patientName: patientName,
          onReject: (reason) =>
              repo.cancelTransfer(patientId: patientId, reason: reason),
        ),
      ),
    );
    if (ok != true || !context.mounted) return false;
    showAppSnackBar(
      context,
      'Traslado rechazado. El paramédico fue notificado.',
    );
    return true;
  }
}
