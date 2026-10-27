/// Nivel de clasificación TRIAGE; refleja `public.triage_color` en Postgres
///
/// Fuente única para los dos protocolos:
/// - START prehospitalario (paramédico): [startLevels]
/// - Triage hospitalario de cinco niveles (médico): [hospitalLevels]
///
/// Dart puro: la apariencia (colores, etiqueta) vive en `TriageLevelStyle`
/// (`core/theme/triage_level_style.dart`).
enum TriageLevel {
  red('rojo'),
  orange('naranja'),
  yellow('amarillo'),
  green('verde'),
  blue('azul'),
  black('negro');

  const TriageLevel(this.dbValue);

  /// Valor en la columna `triage_color`
  final String dbValue;

  static TriageLevel? fromDb(String? raw) {
    for (final level in values) {
      if (level.dbValue == raw) return level;
    }
    return null;
  }

  /// Colores del protocolo START (en orden de prioridad)
  static const List<TriageLevel> startLevels = [red, yellow, green, black];

  /// Niveles 1 a 5 del triage hospitalario
  static const List<TriageLevel> hospitalLevels = [
    red,
    orange,
    yellow,
    green,
    blue,
  ];
}
