import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Apariencia de cada [TriageLevel] según Figma
///
/// Única fuente de colores de triage para los componentes del rediseño
/// (botón de color, tarjeta de paciente, conteo, métrica, marcadores).
extension TriageLevelStyle on TriageLevel {
  /// Color sólido del nivel (barra, botón, marcador)
  Color get color => switch (this) {
    TriageLevel.red => TriageColors.triageRed,
    TriageLevel.orange => TriageColors.triageOrange,
    TriageLevel.yellow => TriageColors.triageYellow,
    TriageLevel.green => TriageColors.triageGreen,
    TriageLevel.blue => TriageColors.triageBlue,
    TriageLevel.black => TriageColors.triageBlack,
  };

  /// Fondo tenue (métricas); Figma no lo define para naranja ni azul
  Color? get background => switch (this) {
    TriageLevel.red => TriageColors.triageRedBackground,
    TriageLevel.yellow => TriageColors.triageYellowBackground,
    TriageLevel.green => TriageColors.triageGreenBackground,
    TriageLevel.black => TriageColors.triageBlackBackground,
    TriageLevel.orange || TriageLevel.blue => null,
  };

  /// Color de texto e íconos sobre [color]
  ///
  /// Oscuro sobre amarillo y naranja: Figma usa blanco en naranja, pero da 2.94:1,
  /// por debajo del mínimo WCAG; con texto oscuro sube a 6.01:1.
  Color get onColor => switch (this) {
    TriageLevel.yellow || TriageLevel.orange => TriageColors.textPrimary,
    _ => TriageColors.textInverse,
  };

  /// Nombre visible del color
  String get label => switch (this) {
    TriageLevel.red => 'Rojo',
    TriageLevel.orange => 'Naranja',
    TriageLevel.yellow => 'Amarillo',
    TriageLevel.green => 'Verde',
    TriageLevel.blue => 'Azul',
    TriageLevel.black => 'Negro',
  };
}
