import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';

/// Panel con el historial de notificaciones del médico (campana del header)
class MedicoNotificationsPanel extends StatelessWidget {
  const MedicoNotificationsPanel({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  final List<MedicoNotificationItem> items;
  final Future<void> Function(MedicoNotificationItem item) onItemTap;

  static String _fmtTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.72;

    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notificaciones',
                    style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                items.isEmpty
                    ? Center(
                      child: Text(
                        'Sin notificaciones',
                        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final n = items[i];
                        return ListTile(
                          leading:
                              n.isUnread
                                  ? Container(
                                    width: 10,
                                    height: 10,
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFB020),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                  : const SizedBox(width: 10),
                          title: Text(
                            n.title.trim().isEmpty
                                ? 'Notificación'
                                : n.title,
                            style: AppTextStyles.ESC_SemiBold_bodyMedium,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.body.trim().isEmpty
                                      ? 'Sin detalle'
                                      : n.body,
                                  style: AppTextStyles.ESC_Regular_bodyMedium
                                      .copyWith(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fmtTime(n.createdAt),
                                  style: AppTextStyles.ESC_Regular_bodyMedium
                                      .copyWith(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () => onItemTap(n),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
