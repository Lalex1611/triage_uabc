import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Tarjeta de sección del rediseño (B10, B13, B20, C02, C03, C06 y C13)
///
/// Agrupa contenido bajo un [title] opcional, con un [trailing] a la derecha:
/// una [TriageSectionAction] ("Editar", "Añadir") o una insignia de estado. Si
/// título y [trailing] no caben en una línea, [trailing] baja a la siguiente.
class TriageSectionCard extends StatelessWidget {
  const TriageSectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final trailing = this.trailing;
    final hasHeader = title != null || trailing != null;
    // La zona táctil de la acción ya deja aire arriba y abajo
    final hasAction = trailing is TriageSectionAction;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(TriageRadii.xl),
        border: Border.all(
          color: TriageColors.borderSubtle,
          width: TriageSizes.stroke,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          TriageSpacing.lg,
          hasAction ? TriageSpacing.xs : TriageSpacing.lg,
          TriageSpacing.lg,
          TriageSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasHeader) ...[
              // Wrap: ancho completo para que spaceBetween lleve [trailing] a la derecha
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: title == null
                      ? WrapAlignment.end
                      : WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: TriageSpacing.sm,
                  runSpacing: TriageSpacing.xs,
                  children: [
                    if (title != null)
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: TriageTextStyles.labelLarge.copyWith(
                            color: TriageColors.textPrimary,
                          ),
                        ),
                      ),
                    ?trailing,
                  ],
                ),
              ),
              SizedBox(height: hasAction ? TriageSpacing.xs : TriageSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Acción de texto en la cabecera de una [TriageSectionCard]
///
/// Toma el color del rol activo. El texto es pequeño, pero su zona táctil
/// llega a [TriageSizes.touchTargetCompact].
class TriageSectionAction extends StatelessWidget {
  const TriageSectionAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;

  /// Ruta de `TriageIcons`
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final accent = context.triageRole.accent;

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TriageRadii.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: TriageSizes.touchTargetCompact,
                minHeight: TriageSizes.touchTargetCompact,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TriageSpacing.xxs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      TriageIcon(
                        icon,
                        size: TriageSizes.iconXSmall,
                        color: accent,
                      ),
                      const SizedBox(width: TriageSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: TriageTextStyles.labelMedium.copyWith(
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
