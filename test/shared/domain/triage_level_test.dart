import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

void main() {
  test(
    'dbValue coincide con public.triage_color y fromDb hace el viaje de vuelta',
    () {
      expect(TriageLevel.values.map((l) => l.dbValue), [
        'rojo',
        'naranja',
        'amarillo',
        'verde',
        'azul',
        'negro',
      ]);
      for (final level in TriageLevel.values) {
        expect(TriageLevel.fromDb(level.dbValue), level);
      }
    },
  );

  test('fromDb devuelve null para valores desconocidos o nulos', () {
    expect(TriageLevel.fromDb(null), isNull);
    expect(TriageLevel.fromDb(''), isNull);
    expect(TriageLevel.fromDb('ROJO'), isNull);
    expect(TriageLevel.fromDb('morado'), isNull);
  });

  test('protocolos: START de 4 colores y hospitalario de 5 niveles', () {
    expect(TriageLevel.startLevels, [
      TriageLevel.red,
      TriageLevel.yellow,
      TriageLevel.green,
      TriageLevel.black,
    ]);
    expect(TriageLevel.hospitalLevels, [
      TriageLevel.red,
      TriageLevel.orange,
      TriageLevel.yellow,
      TriageLevel.green,
      TriageLevel.blue,
    ]);
  });
}
