import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Barra vertical con el color de un nivel de triage (Figma "TRIAGE/Barra de color")
///
/// Crece con su fila: colocarla en un `Row` estirado dentro de un `IntrinsicHeight`.
/// El lector de pantalla anuncia el nivel, porque el color por sí solo no lo dice.
class TriageLevelBar extends StatelessWidget {
  const TriageLevelBar(
    this.level, {
    super.key,
    this.width = _defaultWidth,
    this.minHeight = _defaultMinHeight,
  });

  final TriageLevel level;
  final double width;
  final double minHeight;

  static const double _defaultWidth = 5;
  static const double _defaultMinHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Triage ${level.label}',
      child: Container(
        width: width,
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: level.color,
          borderRadius: BorderRadius.circular(TriageRadii.full),
        ),
      ),
    );
  }
}
