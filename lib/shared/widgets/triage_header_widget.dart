import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_button_widget.dart';

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
/// - Con [badge], [title] pasa a ser una etiqueta discreta junto a la insignia
///   ("INC-729 · ACTIVO", B07); si no caben, la insignia baja de línea.
/// - [showDivider] en `false` cuando debajo sigue contenido de la misma superficie.
class TriageDetailHeader extends StatelessWidget {
  const TriageDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onMore,
    this.useCloseIcon = false,
    this.badge,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final bool useCloseIcon;
  final Widget? badge;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final back = onBack ?? (canPop ? () => Navigator.maybePop(context) : null);
    final badge = this.badge;

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
                        TriageIconButton(
                          icon: useCloseIcon
                              ? TriageIcons.close
                              : TriageIcons.arrowLeft,
                          tooltip: useCloseIcon ? 'Cerrar' : 'Regresar',
                          onPressed: back,
                          variant: TriageIconButtonVariant.plain,
                          iconSize: TriageSizes.iconLarge,
                        ),
                        const SizedBox(width: TriageSpacing.xs),
                      ],
                      Expanded(
                        child: badge != null
                            ? Wrap(
                                spacing: TriageSpacing.sm,
                                runSpacing: TriageSpacing.xs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      title,
                                      style: TriageTextStyles.labelMedium
                                          .copyWith(
                                            color: TriageColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                  badge,
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      title,
                                      style: TriageTextStyles.titleMedium
                                          .copyWith(
                                            color: TriageColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                  if (subtitle != null)
                                    Text(
                                      subtitle!,
                                      style: TriageTextStyles.bodySmall
                                          .copyWith(
                                            color: TriageColors.textSecondary,
                                          ),
                                    ),
                                ],
                              ),
                      ),
                      if (onMore != null) ...[
                        const SizedBox(width: TriageSpacing.xs),
                        TriageIconButton(
                          icon: TriageIcons.more,
                          tooltip: 'Más opciones',
                          onPressed: onMore,
                          variant: TriageIconButtonVariant.plain,
                          color: TriageColors.textSecondary,
                          iconSize: TriageSizes.iconLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (showDivider)
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
