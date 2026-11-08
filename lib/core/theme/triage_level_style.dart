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
  /// Oscuro sobre amarillo, naranja y verde para llegar a 4.5:1 (WCAG AA texto
  /// normal): Figma usa blanco en naranja (2.94:1) y verde (3.30:1); con texto
  /// oscuro suben a 6.01:1 y 5.35:1.
  Color get onColor => switch (this) {
    TriageLevel.yellow ||
    TriageLevel.orange ||
    TriageLevel.green => TriageColors.textPrimary,
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

  /// Nombre en el protocolo START; `null` si el color no pertenece a él
  String? get startName => switch (this) {
    TriageLevel.red => 'Inmediato',
    TriageLevel.yellow => 'Urgente',
    TriageLevel.green => 'Leve',
    TriageLevel.black => 'Fallecido',
    TriageLevel.orange || TriageLevel.blue => null,
  };

  /// Cuándo se asigna en el protocolo START; `null` si no pertenece a él
  String? get startDetail => switch (this) {
    TriageLevel.red => 'No camina · no responde',
    TriageLevel.yellow => 'Puede esperar atención',
    TriageLevel.green => 'Camina por sí mismo',
    TriageLevel.black => 'Sin signos vitales',
    TriageLevel.orange || TriageLevel.blue => null,
  };

  /// Nombre en el triage hospitalario; `null` si el color no pertenece a él
  String? get hospitalName => switch (this) {
    TriageLevel.red => 'Resucitación',
    TriageLevel.orange => 'Emergencia',
    TriageLevel.yellow => 'Urgente',
    TriageLevel.green => 'Poco urgente',
    TriageLevel.blue => 'No urgente',
    TriageLevel.black => null,
  };

  /// Plazo de atención en el triage hospitalario; `null` si no pertenece a él
  String? get hospitalDetail => switch (this) {
    TriageLevel.red => 'Atención inmediata',
    TriageLevel.orange => 'Atender antes de 10 min',
    TriageLevel.yellow => 'Atender antes de 60 min',
    TriageLevel.green => 'Atender antes de 2 h',
    TriageLevel.blue => 'Consulta general',
    TriageLevel.black => null,
  };
}
