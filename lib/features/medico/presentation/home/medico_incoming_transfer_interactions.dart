import 'package:flutter/material.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/medico_accept_transfer_page.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/medico_reject_transfer_page.dart';

/// Recibir o rechazar a un paciente en **trasladando** (Entradas o revisión).
/// Abre las pantallas de los mockups 03 (confirmar recepción) y 04 (rechazar
/// traslado). Devuelven `true` si la acción se completó.
class MedicoIncomingTransferInteractions {
  MedicoIncomingTransferInteractions._();

  static Future<bool> acceptIncoming({
    required BuildContext context,
    required MedicoIncomingReview review,
    PatientsRepository? repository,
  }) async {
    final repo = repository ?? PatientsRepository();
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MedicoAcceptTransferPage(
          review: review,
          onConfirm: () => repo.receivePatient(patientId: review.patientId),
        ),
      ),
    );
    if (ok != true || !context.mounted) return false;
    showAppSnackBar(context, 'Paciente recibido. Ya está en la sala.');
    return true;
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
