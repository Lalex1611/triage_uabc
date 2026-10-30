import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Zona táctil de los botones del encabezado (Material / `kMinInteractiveDimension`)
const double _touchTarget = 48;

/// Encabezado de inicio del rediseño (Figma "TRIAGE/Encabezado", Tipo=Inicio)
///
/// Banda con el color del rol activo ([TriageRoleTheme]): rojo en campo, azul
/// en hospital. Va como primer hijo del cuerpo de la pantalla (no en
/// `Scaffold.appBar`) para crecer si el usuario agranda el texto; se pinta
/// detrás de la barra del sistema y pone sus íconos en claro.
///
/// - [eyebrow] arriba del título ("Paramédico en turno", "SALA HOSPITALARIA").
/// - [subtitle] debajo del título ("Hospital General de Tijuana · Urgencias").
/// - Avatar solo con [onProfileTap]; campana solo con [onNotificationsTap].
/// - [bottom]: contenido extra dentro de la banda (métricas de C01, niveles de C05).
class TriageHomeHeader extends StatelessWidget {
  const TriageHomeHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.onProfileTap,
    this.onNotificationsTap,
    this.hasNotifications = false,
    this.bottom,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final bool hasNotifications;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    // Texto en blanco sólido: el 75-80 % de Figma no llega a 4.5:1 sobre la banda
    const onBand = TriageColors.textInverse;
    final bottom = this.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: context.triageRole.accent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Relleno de Figma menos lo que la zona de 48 sobresale del círculo
              Padding(
                padding: EdgeInsets.fromLTRB(
                  onProfileTap == null ? 20 : 18,
                  2,
                  onNotificationsTap == null ? 20 : 16,
                  bottom == null ? 20 : 14,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _touchTarget),
                  child: Row(
                    children: [
                      if (onProfileTap != null) ...[
                        _HeaderButton(
                          icon: TriageIcons.user,
                          tooltip: 'Perfil',
                          onPressed: onProfileTap,
                          diameter: 44,
                          iconColor: onBand,
                          background: onBand.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: Text(
                                  eyebrow!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TriageTextStyles.labelSmall.copyWith(
                                    color: onBand,
                                  ),
                                ),
                              ),
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TriageTextStyles.titleMedium.copyWith(
                                  color: onBand,
                                ),
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TriageTextStyles.bodySmall.copyWith(
                                  color: onBand,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onNotificationsTap != null) ...[
                        const SizedBox(width: 8),
                        _HeaderButton(
                          icon: TriageIcons.bell,
                          tooltip: hasNotifications
                              ? 'Notificaciones, hay avisos nuevos'
                              : 'Notificaciones',
                          onPressed: onNotificationsTap,
                          iconSize: 20,
                          iconColor: onBand,
                          background: onBand.withValues(alpha: 0.16),
                          showDot: hasNotifications,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: bottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de detalle del rediseño (Figma "TRIAGE/Encabezado", Tipo=Detalle)
///
/// Superficie blanca con línea superior del color del rol activo. Va como
/// primer hijo del cuerpo de la pantalla (no en `Scaffold.appBar`) para crecer
/// si el usuario agranda el texto; pone los íconos de la barra del sistema en oscuro.
///
/// - Sin [onBack], la flecha aparece sola si la ruta se puede cerrar y llama a
///   `Navigator.maybePop`, igual que `AppBar` y el botón atrás de Android.
/// - "Más opciones" solo con [onMore].
class TriageDetailHeader extends StatelessWidget {
  const TriageDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onMore,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final back = onBack ?? (canPop ? () => Navigator.maybePop(context) : null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Material(
        color: TriageColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 3,
              child: ColoredBox(color: context.triageRole.accent),
            ),
            SafeArea(
              bottom: false,
              // Fila de 56 como Figma: botón de 48 + 8 abajo
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  back == null ? 14 : 10,
                  0,
                  onMore == null ? 14 : 10,
                  8,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _touchTarget),
                  child: Row(
                    children: [
                      if (back != null) ...[
                        _HeaderButton(
                          icon: TriageIcons.arrowLeft,
                          tooltip: 'Regresar',
                          onPressed: back,
                          iconColor: TriageColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TriageTextStyles.titleMedium.copyWith(
                                  color: TriageColors.textPrimary,
                                ),
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TriageTextStyles.bodySmall.copyWith(
                                  color: TriageColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onMore != null) ...[
                        const SizedBox(width: 6),
                        _HeaderButton(
                          icon: TriageIcons.more,
                          tooltip: 'Más opciones',
                          onPressed: onMore,
                          iconColor: TriageColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: TriageColors.borderSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón redondo del encabezado: círculo visible de [diameter] dentro de una
/// zona táctil de 48; [showDot] añade el punto de avisos con anillo blanco
/// (rojo sobre la banda no llega a 3:1 sin él).
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.iconColor,
    this.iconSize = 22,
    this.diameter = 40,
    this.background,
    this.showDot = false,
  });

  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;
  final double diameter;
  final Color? background;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: background == null
          ? null
          : BoxDecoration(color: background, shape: BoxShape.circle),
      child: TriageIcon(icon, size: iconSize, color: iconColor),
    );

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _touchTarget,
        height: _touchTarget,
      ),
      icon: !showDot
          ? circle
          : Stack(
              clipBehavior: Clip.none,
              children: [
                circle,
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    key: const ValueKey('triage-header-dot'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: TriageColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TriageColors.textInverse,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
