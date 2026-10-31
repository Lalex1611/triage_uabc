import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Pastilla de color del rediseño (Figma "TRIAGE/Pastilla de color")
///
/// Nombre del nivel en mayúsculas sobre su color (p. ej. "ROJO" en la tarjeta
/// de entrante de C01). El texto usa [TriageLevelStyle.onColor] para llegar a
/// 4.5:1 en todos los niveles.
class TriageLevelPill extends StatelessWidget {
  const TriageLevelPill(this.level, {super.key});

  final TriageLevel level;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Triage ${level.label}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: ShapeDecoration(
          color: level.color,
          shape: const StadiumBorder(),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            level.label.toUpperCase(),
            style: TriageTextStyles.labelSmall.copyWith(color: level.onColor),
          ),
        ),
      ),
    );
  }
}
