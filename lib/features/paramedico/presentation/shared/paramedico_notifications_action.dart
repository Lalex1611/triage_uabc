import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/notifications/paramedic_notification.dart';
import 'package:sistema_triage/features/paramedico/presentation/notifications/widgets/paramedic_notifications_sheet_widget.dart';

class ParamedicoNotificationsAction {
  ParamedicoNotificationsAction._();

  static Future<int> unreadCount(ParamedicNotificationsRepository repo) async {
    try {
      return await repo.countUnread();
    } catch (_) {
      return 0;
    }
  }

  static Future<void> open(
    BuildContext context, {
    required ParamedicNotificationsRepository repository,
    ValueChanged<int>? onUnreadChanged,
  }) async {
    List<ParamedicNotification> items = [];
    try {
      items = await repository.listRecent();
      onUnreadChanged?.call(items.where((n) => n.isUnread).length);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron cargar notificaciones: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return ParamedicNotificationsSheet(
          notifications: items,
          onClose: () => Navigator.pop(ctx),
          onNotificationTap: (n) async {
            if (n.isUnread) {
              await repository.markRead(n.id);
            }
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (!context.mounted) return;
            _showNotificationToast(context, n);
            onUnreadChanged?.call(await unreadCount(repository));
          },
        );
      },
    );
  }

  static void _showNotificationToast(BuildContext context, ParamedicNotification n) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final patientLabel = n.patientDisplayName?.trim();
    final message = [
      if (patientLabel != null && patientLabel.isNotEmpty) patientLabel,
      n.body,
    ].where((s) => s.trim().isNotEmpty).join('\n');

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 7),
          content: Text(message.isEmpty ? n.title : message),
          action: n.patientId == null || n.patientId!.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Ir a paciente',
                  onPressed: () {
                    if (!context.mounted) return;
                    unawaited(
                      pushParamedicoFullScreen(
                        context,
                        '/paramedico/patient/${n.patientId}',
                      ),
                    );
                  },
                ),
        ),
      );
  }
}
