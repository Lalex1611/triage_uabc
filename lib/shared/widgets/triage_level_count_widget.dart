import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Conteo de pacientes por nivel del rediseño (Figma "TRIAGE/Conteo")
///
/// Un cuadro por nivel de [levels] (por defecto los colores START) con su
/// cantidad en [counts]; un nivel ausente cuenta 0. Si no caben en el ancho
/// (pantalla angosta o texto grande) pasan a otra línea. El lector de pantalla
/// lo anuncia como una sola frase: "Rojo: 3, Amarillo: 2…".
class TriageLevelCount extends StatelessWidget {
  const TriageLevelCount({
    super.key,
    required this.counts,
    this.levels = TriageLevel.startLevels,
  });

  final Map<TriageLevel, int> counts;
  final List<TriageLevel> levels;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: [
        for (final l in levels) '${l.label}: ${counts[l] ?? 0}',
      ].join(', '),
      excludeSemantics: true,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final level in levels)
            Container(
              // Mínimos de Figma (30×26); crece con números de dos cifras
              constraints: const BoxConstraints(minWidth: 30, minHeight: 26),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: level.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  '${counts[level] ?? 0}',
                  style: TriageTextStyles.labelMedium.copyWith(
                    color: level.onColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
