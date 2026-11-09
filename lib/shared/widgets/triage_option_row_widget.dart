import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_option_text_widget.dart';

/// Fila de opción para hojas inferiores: ícono, título y una línea de detalle
///
/// - Por defecto, una acción ("Editar incidente").
/// - [TriageOptionRow.check]: elegir un criterio ("Ordenar incidentes").
/// - [TriageOptionRow.toggle]: encender o apagar algo ("Capas del mapa").
///
/// Toda la fila responde al toque, con alto mínimo táctil, y crece con el texto.
class TriageOptionRow extends StatelessWidget {
  const TriageOptionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  }) : selected = null,
       toggled = null;

  const TriageOptionRow.check({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required bool this.selected,
    required this.onTap,
  }) : toggled = null;

  TriageOptionRow.toggle({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) : selected = null,
       toggled = value,
       onTap = (() => onChanged(!value));

  /// Ruta de [TriageIcons]
  final String icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  /// Solo en [TriageOptionRow.check]
  final bool? selected;

  /// Solo en [TriageOptionRow.toggle]
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    final toggled = this.toggled;
    final accent = context.triageRole.accent;
    final isSelected = selected ?? false;

    return MergeSemantics(
      child: Semantics(
        button: toggled == null,
        selected: selected,
        toggled: toggled,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TriageSizes.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TriageSpacing.xl,
                vertical: TriageSpacing.md,
              ),
              child: Row(
                children: [
                  TriageIcon(
                    icon,
                    size: TriageSizes.icon,
                    color: isSelected ? accent : TriageColors.textSecondary,
                  ),
                  const SizedBox(width: TriageSpacing.md),
                  Expanded(
                    child: TriageOptionText(
                      title: title,
                      detail: detail,
                      titleColor: isSelected
                          ? accent
                          : TriageColors.textPrimary,
                    ),
                  ),
                  if (toggled != null) ...[
                    const SizedBox(width: TriageSpacing.md),
                    _SwitchIndicator(value: toggled, accent: accent),
                  ] else if (selected != null) ...[
                    const SizedBox(width: TriageSpacing.md),
                    // Espacio reservado: elegir no cambia cómo parte el texto
                    SizedBox.square(
                      dimension: TriageSizes.icon,
                      child: selected
                          ? TriageIcon(
                              TriageIcons.check,
                              size: TriageSizes.icon,
                              color: accent,
                            )
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Solo visual: el toque y el estado para el lector los da la fila
class _SwitchIndicator extends StatelessWidget {
  const _SwitchIndicator({required this.value, required this.accent});

  final bool value;
  final Color accent;

  static const _width = 46.0;
  static const _height = 27.0;
  static const _inset = 3.0;

  @override
  Widget build(BuildContext context) {
    final height = context.rDim(_height);
    final inset = context.rDim(_inset);

    return AnimatedContainer(
      duration: kThemeAnimationDuration,
      width: context.rDim(_width),
      height: height,
      padding: EdgeInsets.all(inset),
      alignment: value
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        // Figma usa borderStrong, que no llega a 3:1 sobre blanco
        color: value ? accent : TriageColors.textTertiary,
        borderRadius: BorderRadius.circular(TriageRadii.full),
      ),
      child: SizedBox.square(
        dimension: height - 2 * inset,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: TriageColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
