import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/notifications/paramedic_notification.dart';
import 'package:sistema_triage/features/paramedico/presentation/notifications/widgets/paramedic_notifications_modal_widget.dart';

class ParamedicoNotificationsAction {
  ParamedicoNotificationsAction._();

  static Future<int> unreadCount(ParamedicNotificationsRepository repo) async {
    try {
      return await repo.countUnread();
    } catch (_) {
      return 0;
    }
  }

  /// Abre el "Modal - Notificaciones". Tocar una la marca como leída y, si es
  /// de un paciente, cierra el modal y abre su detalle.
  static Future<void> open(
    BuildContext context, {
    required ParamedicNotificationsRepository repository,
    ValueChanged<int>? onUnreadChanged,
  }) async {
    List<ParamedicNotification> items = [];
    try {
      items = await repository.listRecent();
      onUnreadChanged?.call(items.where((n) => n.isUnread).length);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'No se pudieron cargar las notificaciones.',
          isError: true,
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (modalContext) => ParamedicNotificationsModal(
        notifications: items,
        onNotificationTap: (n) async {
          // Si falla, el modal lo avisa y deja la notificación sin leer
          if (n.isUnread) {
            await repository.markRead(n.id);
            onUnreadChanged?.call(await unreadCount(repository));
          }
          final patientId = n.patientId;
          if (patientId == null || patientId.isEmpty) return;
          // Si lo cerraron mientras se marcaba, no se navega por sorpresa
          if (!modalContext.mounted) return;
          Navigator.pop(modalContext);
          if (context.mounted) {
            unawaited(
              pushParamedicoFullScreen(
                context,
                '/paramedico/patient/$patientId',
              ),
            );
          }
        },
      ),
    );
  }
}
