import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_tap_card_widget.dart';

/// Botón de color del rediseño (Figma "TRIAGE/Botón de color", B11, B12 y C07)
///
/// - [TriageLevelButton.start]: clasificación START (rojo, amarillo, verde, negro).
/// - [TriageLevelButton.hospital]: triage hospitalario de cinco niveles.
/// - Por defecto, textos propios para los casos que Figma cambia por instancia.
///
/// Seleccionado: borde oscuro, sombra y palomita, para no depender solo del
/// color. Ocupa el ancho disponible y crece con el texto; para la cuadrícula de
/// Figma, dos por fila con `Expanded` e `IntrinsicHeight`. Los textos son sólidos:
/// el 85 % de opacidad de Figma no siempre llega a 4.5:1.
class TriageLevelButton extends StatelessWidget {
  const TriageLevelButton({
    super.key,
    required this.level,
    required this.tag,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  /// [level] debe ser uno de [TriageLevel.startLevels]
  TriageLevelButton.start(
    this.level, {
    super.key,
    required this.selected,
    required this.onTap,
  }) : assert(TriageLevel.startLevels.contains(level)),
       tag = level.label.toUpperCase(),
       title = level.startName!,
       detail = level.startDetail!;

  /// [level] debe ser uno de [TriageLevel.hospitalLevels]
  TriageLevelButton.hospital(
    this.level, {
    super.key,
    required this.selected,
    required this.onTap,
  }) : assert(TriageLevel.hospitalLevels.contains(level)),
       tag =
           'NIVEL ${TriageLevel.hospitalLevels.indexOf(level) + 1} · '
           '${level.label.toUpperCase()}',
       title = level.hospitalName!,
       detail = level.hospitalDetail!;

  final TriageLevel level;

  /// Línea superior, en mayúsculas ("ROJO", "NIVEL 1 · ROJO")
  final String tag;
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  static const _minHeight = 96.0;
  static const _selectedBorder = 3.0;
  static const _idleOpacity = 0.94;

  @override
  Widget build(BuildContext context) {
    final foreground = level.onColor;

    return TriageTapCard(
      onTap: onTap,
      selected: selected,
      color: selected
          ? level.color
          : level.color.withValues(alpha: _idleOpacity),
      borderColor: selected ? TriageColors.textPrimary : null,
      borderWidth: _selectedBorder,
      shadow: selected ? TriageShadows.floating : null,
      inkColor: foreground,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TriageSpacing.lg,
            vertical: TriageSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tag,
                      style: TriageTextStyles.labelSmall.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: TriageSpacing.xs),
                  // Espacio reservado: seleccionar no mueve la cuadrícula
                  SizedBox.square(
                    dimension: TriageSizes.iconSmall,
                    child: selected
                        ? TriageIcon(
                            TriageIcons.checkCircle,
                            size: TriageSizes.iconSmall,
                            color: foreground,
                          )
                        : null,
                  ),
                ],
              ),
              Text(
                title,
                style: TriageTextStyles.titleMedium.copyWith(color: foreground),
              ),
              Text(
                detail,
                style: TriageTextStyles.bodySmall.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
