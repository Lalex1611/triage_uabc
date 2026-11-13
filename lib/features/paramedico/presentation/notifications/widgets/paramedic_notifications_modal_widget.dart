import 'package:flutter/material.dart';
import 'package:sistema_triage/core/util/time_ago.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/notifications/paramedic_notification.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// "Modal - Notificaciones" del paramédico: ventana centrada que se abre con
/// `showDialog`. La cabecera cuenta las que siguen sin leer y la lista se
/// desplaza dentro de la ventana si no cabe.
///
/// Al tocar una notificación espera a [onNotificationTap] (la marca como leída)
/// y entonces la pinta leída; si falla, se queda como estaba.
class ParamedicNotificationsModal extends StatefulWidget {
  const ParamedicNotificationsModal({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
  });

  final List<ParamedicNotification> notifications;
  final Future<void> Function(ParamedicNotification notification)
  onNotificationTap;

  @override
  State<ParamedicNotificationsModal> createState() =>
      _ParamedicNotificationsModalState();
}

class _ParamedicNotificationsModalState
    extends State<ParamedicNotificationsModal> {
  final _readIds = <String>{};

  // Medidas del modal en Figma; en pantallas más bajas manda el margen del diálogo
  static const _maxWidth = 416.0;
  static const _maxHeight = 517.0;
  static const _radius = BorderRadius.all(Radius.circular(TriageRadii.xxl));

  bool _unread(ParamedicNotification n) =>
      n.isUnread && !_readIds.contains(n.id);

  Future<void> _open(ParamedicNotification n) async {
    try {
      await widget.onNotificationTap(n);
    } catch (_) {
      return; // El aviso del error lo da quien abre el modal
    }
    if (mounted) setState(() => _readIds.add(n.id));
  }

  // shortcut: el backend solo emite 'transfer_cancelled'; el resto de tipos de
  // Figma (aceptado, disponibilidad, alta, unidad) se añaden aquí cuando existan
  static (String, TriageTone) _look(String kind) => switch (kind) {
    'transfer_cancelled' => (TriageIcons.reject, TriageTone.danger),
    _ => (TriageIcons.bell, TriageTone.info),
  };

  static String _message(ParamedicNotification n) {
    final patient = n.patientDisplayName?.trim() ?? '';
    return patient.isEmpty ? n.body : '$patient: ${n.body}';
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.notifications;
    final unread = items.where(_unread).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TriageSpacing.md,
        vertical: TriageSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _maxWidth,
          maxHeight: _maxHeight,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: _radius,
            boxShadow: TriageShadows.floating,
          ),
          child: Material(
            color: TriageColors.surface,
            borderRadius: _radius,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    TriageSpacing.md,
                    TriageSpacing.md,
                    TriageSpacing.xs,
                    TriageSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Notificaciones',
                                style: TriageTextStyles.titleMedium.copyWith(
                                  color: TriageColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              unread == 0 ? 'Todas leídas' : '$unread sin leer',
                              style: TriageTextStyles.bodySmall.copyWith(
                                color: TriageColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TriageIconButton(
                        icon: TriageIcons.close,
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                        variant: TriageIconButtonVariant.plain,
                        iconSize: TriageSizes.iconLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: TriageSizes.hairline,
                  thickness: TriageSizes.hairline,
                  color: TriageColors.borderSubtle,
                ),
                Flexible(
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(TriageSpacing.xl),
                          child: Text(
                            'No tienes notificaciones por ahora.',
                            style: TriageTextStyles.bodySmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(
                            TriageSpacing.sm,
                            TriageSpacing.md,
                            TriageSpacing.sm,
                            TriageSpacing.xl,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: TriageSpacing.sm),
                          itemBuilder: (context, index) {
                            final n = items[index];
                            final (icon, tone) = _look(n.kind);
                            return TriageNotificationCard(
                              icon: icon,
                              tone: tone,
                              title: n.title,
                              message: _message(n),
                              timeAgo: timeAgo(n.createdAt),
                              unread: _unread(n),
                              onTap: () => _open(n),
                            );
                          },
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
