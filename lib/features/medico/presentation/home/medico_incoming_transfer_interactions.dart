import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_transfer_accept_confirm_dialog.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_transfer_cancel_confirm_dialog.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_transfer_cancel_reason_dialog.dart';

/// Acciones de alta frecuencia al recibir paciente en **trasladando** desde el médico (home o detalle)
class MedicoIncomingTransferInteractions {
  MedicoIncomingTransferInteractions._();

  static Future<bool> acceptIncoming({
    required BuildContext context,
    required String patientId,
    PatientsRepository? repository,
  }) async {
    final repo = repository ?? PatientsRepository();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return MedicoTransferAcceptConfirmDialog(
          onBackTap: () => Navigator.of(ctx).pop(false),
          onConfirmTap: () => Navigator.of(ctx).pop(true),
        );
      },
    );
    if (confirmed != true || !context.mounted) return false;

    try {
      await repo.receivePatient(patientId: patientId);
      if (!context.mounted) return false;
      showAppSnackBar(context, 'Paciente aceptado (recibido).');
      return true;
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
      return false;
    }
  }

  /// Mismo flujo de diálogos que antes en detalle (cancelar motivo → RPC Supabase)
  static Future<bool> rejectIncomingTransfer({
    required BuildContext context,
    required String patientId,
    PatientsRepository? repository,
  }) async {
    final repo = repository ?? PatientsRepository();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return MedicoTransferCancelConfirmDialog(
          onBackTap: () => Navigator.of(ctx).pop(false),
          onConfirmTap: () => Navigator.of(ctx).pop(true),
        );
      },
    );
    if (confirmed != true || !context.mounted) return false;

    final Completer<bool> finished = Completer<bool>();

    if (!context.mounted) return false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (reasonCtx) {
        return MedicoTransferCancelReasonDialog(
          onBackTap: () {
            Navigator.of(reasonCtx).pop();
            if (!finished.isCompleted) {
              finished.complete(false);
            }
          },
          onSubmit: (reason) async {
            Navigator.of(reasonCtx).pop();
            try {
              await repo.cancelTransfer(
                patientId: patientId,
                reason: reason.trim(),
              );
              if (!context.mounted) {
                if (!finished.isCompleted) finished.complete(false);
                return;
              }
              showAppSnackBar(
                context,
                'Traslado rechazado. El paramédico fue notificado.',
              );
              if (!finished.isCompleted) finished.complete(true);
            } catch (e) {
              if (context.mounted) {
                showAppSnackBar(context, '$e', isError: true);
              }
              if (!finished.isCompleted) finished.complete(false);
            }
          },
        );
      },
    );

    return await finished.future;
  }
}
