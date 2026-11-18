import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/presentation/notifications/medico_notification_format.dart';

/// Tarjeta de una notificación (mockup 12). Sin leer: fondo blanco, sombra y
/// punto azul; leída: fondo plano.
class MedicoNotificationCard extends StatelessWidget {
  const MedicoNotificationCard({
    super.key,
    required this.view,
    required this.timeLabel,
    required this.unread,
    this.onTap,
  });

  final MedicoNotificationView view;
  final String timeLabel;
  final bool unread;
  final VoidCallback? onTap;

  static const _dot = Color(0xFF1C69AA);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: unread
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: unread ? Colors.white : const Color(0xFFF4F6F9),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: unread
                    ? const Color(0xFFE1E7ED)
                    : const Color(0xFFE6EAEF),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: view.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(view.icon, size: 21, color: view.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        view.body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF3F4850),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8A949E),
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(left: 8, top: 5),
                    decoration: const BoxDecoration(
                      color: _dot,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
