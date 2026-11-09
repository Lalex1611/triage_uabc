import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Relleno horizontal de la banda y del encabezado de detalle
const double _gutter = TriageSpacing.xl;

/// Diámetro del avatar y de la campana (Figma)
const double _avatarDiameter = TriageSizes.touchTargetCompact;
const double _bellDiameter = 40;

/// Lo que la zona táctil de un botón sobresale de su círculo visible, para
/// restarlo del relleno y que el círculo quede donde lo pone Figma
double _overhang(double diameter) => (TriageSizes.touchTarget - diameter) / 2;

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
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(TriageRadii.xxl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  onProfileTap == null
                      ? _gutter
                      : _gutter - _overhang(_avatarDiameter),
                  TriageSpacing.xxs,
                  onNotificationsTap == null
                      ? _gutter
                      : _gutter - _overhang(_bellDiameter),
                  bottom == null ? _gutter : TriageSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: TriageSizes.touchTarget,
                  ),
                  child: Row(
                    children: [
                      if (onProfileTap != null) ...[
                        _HeaderButton(
                          icon: TriageIcons.user,
                          tooltip: 'Perfil',
                          onPressed: onProfileTap,
                          diameter: _avatarDiameter,
                          iconSize: TriageSizes.iconLarge,
                          iconColor: onBand,
                          background: TriageColors.overlayOnAccent,
                        ),
                        const SizedBox(width: TriageSpacing.sm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: TriageSpacing.xxs,
                                ),
                                child: Text(
                                  eyebrow!,
                                  style: TriageTextStyles.labelSmall.copyWith(
                                    color: onBand,
                                  ),
                                ),
                              ),
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: TriageTextStyles.titleMedium.copyWith(
                                  color: onBand,
                                ),
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: TriageTextStyles.bodySmall.copyWith(
                                  color: onBand,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onNotificationsTap != null) ...[
                        const SizedBox(width: TriageSpacing.sm),
                        _HeaderButton(
                          icon: TriageIcons.bell,
                          tooltip: hasNotifications
                              ? 'Notificaciones, hay avisos nuevos'
                              : 'Notificaciones',
                          onPressed: onNotificationsTap,
                          diameter: _bellDiameter,
                          iconSize: TriageSizes.icon,
                          iconColor: onBand,
                          background: TriageColors.overlayOnAccent,
                          showDot: hasNotifications,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _gutter,
                    0,
                    _gutter,
                    TriageSpacing.lg,
                  ),
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
/// - [useCloseIcon] muestra una X en vez de la flecha, para pantallas que se
///   abandonan sin volver atrás (C03, C09 y C11).
/// - "Más opciones" solo con [onMore].
class TriageDetailHeader extends StatelessWidget {
  const TriageDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onMore,
    this.useCloseIcon = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final bool useCloseIcon;

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
              height: _accentLine,
              child: ColoredBox(color: context.triageRole.accent),
            ),
            SafeArea(
              bottom: false,
              // Fila de 56 como Figma: botón de 48 + sm abajo
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  back == null ? TriageSpacing.lg : TriageSpacing.sm,
                  0,
                  onMore == null ? TriageSpacing.lg : TriageSpacing.sm,
                  TriageSpacing.sm,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: TriageSizes.touchTarget,
                  ),
                  child: Row(
                    children: [
                      if (back != null) ...[
                        _HeaderButton(
                          icon: useCloseIcon
                              ? TriageIcons.close
                              : TriageIcons.arrowLeft,
                          tooltip: useCloseIcon ? 'Cerrar' : 'Regresar',
                          onPressed: back,
                          iconColor: TriageColors.textPrimary,
                        ),
                        const SizedBox(width: TriageSpacing.xs),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: TriageTextStyles.titleMedium.copyWith(
                                  color: TriageColors.textPrimary,
                                ),
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: TriageTextStyles.bodySmall.copyWith(
                                  color: TriageColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onMore != null) ...[
                        const SizedBox(width: TriageSpacing.xs),
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
              height: TriageSizes.hairline,
              thickness: TriageSizes.hairline,
              color: TriageColors.borderSubtle,
            ),
          ],
        ),
      ),
    );
  }

  /// Línea superior del color del rol (Figma)
  static const double _accentLine = 3;
}

/// Botón redondo del encabezado: círculo visible de [diameter] dentro de una
/// zona táctil de [TriageSizes.touchTarget]; [showDot] añade el punto de
/// avisos con anillo blanco (rojo sobre la banda no llega a 3:1 sin él).
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.iconColor,
    this.iconSize = TriageSizes.iconLarge,
    this.diameter = _bellDiameter,
    this.background,
    this.showDot = false,
  });

  // Punto de avisos de Figma: diámetro, anillo y posición relativa al círculo
  static const double _dot = 12;
  static const double _dotRing = 2;
  static const _dotAlignment = Alignment(0.5, -0.5);

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
        width: TriageSizes.touchTarget,
        height: TriageSizes.touchTarget,
      ),
      icon: !showDot
          ? circle
          : Stack(
              alignment: _dotAlignment,
              children: [
                circle,
                Container(
                  key: const ValueKey('triage-header-dot'),
                  width: _dot,
                  height: _dot,
                  decoration: BoxDecoration(
                    color: TriageColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TriageColors.textInverse,
                      width: _dotRing,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
