import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/notifications/paramedic_notification.dart';

// Hoja inferior de notificaciones del paramedico
class ParamedicNotificationsSheet extends StatelessWidget {
  const ParamedicNotificationsSheet({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onClose,
  });

  final List<ParamedicNotification> notifications;
  final ValueChanged<ParamedicNotification> onNotificationTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Notificaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              Text(
                'No hay alertas nuevas por ahora.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.cancel_outlined,
                        color: n.isUnread
                            ? AppColors.primaryParamedico
                            : Colors.black38,
                      ),
                      title: Text(
                        n.title,
                        style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                          fontSize: 14,
                          color: n.isUnread ? Colors.black : Colors.black54,
                        ),
                      ),
                      subtitle: Text(
                        n.patientDisplayName ?? 'Paciente',
                        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      trailing: n.isUnread
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryParamedico,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () => onNotificationTap(n),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryParamedico,
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
