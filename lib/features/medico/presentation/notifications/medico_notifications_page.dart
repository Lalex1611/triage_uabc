import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/medico/presentation/notifications/medico_notification_format.dart';
import 'package:sistema_triage/features/medico/presentation/notifications/widgets/medico_notification_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';

/// Notificaciones del médico (mockup 12): encabezado con cuántas faltan por
/// leer y la lista de tarjetas. Sin lógica de negocio.
class MedicoNotificationsPage extends StatelessWidget {
  const MedicoNotificationsPage({
    super.key,
    required this.items,
    required this.onBackTap,
    required this.onItemTap,
    this.onRefresh,
    this.now,
  });

  final List<MedicoNotificationItem> items;
  final VoidCallback onBackTap;
  final ValueChanged<MedicoNotificationItem> onItemTap;
  final Future<void> Function()? onRefresh;

  /// Para pruebas; por defecto la hora actual
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final t = now ?? DateTime.now();
    final unread = items.where((n) => n.isUnread).length;
    final subtitle = unread == 0
        ? 'Todo leído'
        : unread == 1
        ? '1 sin leer'
        : '$unread sin leer';

    final Widget list = items.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: Color(0xFFA3ADB8),
              ),
              SizedBox(height: 10),
              Text(
                'Sin notificaciones',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF8A949E)),
              ),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final n = items[i];
              return MedicoNotificationCard(
                view: MedicoNotificationFormat.viewOf(n, t),
                timeLabel: MedicoNotificationFormat.relativeTime(
                  n.createdAt,
                  t,
                ),
                unread: n.isUnread,
                onTap: () => onItemTap(n),
              );
            },
          );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: MedicoReviewHeader(
              title: 'Notificaciones',
              subtitle: subtitle,
              onBackTap: onBackTap,
            ),
          ),
          Expanded(
            child: onRefresh == null
                ? list
                : RefreshIndicator(onRefresh: onRefresh!, child: list),
          ),
        ],
      ),
    );
  }
}
