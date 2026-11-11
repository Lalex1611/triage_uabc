import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_protocol.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Recorre el protocolo eligiendo en cada paso la respuesta con ese texto
TriageLevel? _run(List<String> labels) {
  for (final (step, label) in labels.indexed) {
    final answer = startSteps[step].answers.singleWhere(
      (a) => a.label == label,
    );
    if (answer.level != null) return answer.level;
  }
  return null;
}

void main() {
  test('cada camino del protocolo termina en el color de START', () {
    const breathes = ['No camina', 'Sí respira'];
    expect(_run(['Sí, camina']), TriageLevel.green);
    expect(
      _run(['No camina', 'No respira ni al abrir la vía aérea']),
      TriageLevel.black,
    );
    expect(
      _run(['No camina', 'Respira solo al abrir la vía aérea']),
      TriageLevel.red,
    );
    expect(_run([...breathes, 'Más de 30 por minuto']), TriageLevel.red);
    expect(
      _run([
        ...breathes,
        '30 o menos',
        'Llenado mayor a 2 s o sin pulso radial',
      ]),
      TriageLevel.red,
    );
    const stable = [...breathes, '30 o menos', 'Llenado de 2 s o menos'];
    expect(_run([...stable, 'No obedece']), TriageLevel.red);
    expect(_run([...stable, 'Sí obedece']), TriageLevel.yellow);
  });

  test('solo la última pregunta clasifica con todas sus respuestas', () {
    for (final (index, step) in startSteps.indexed) {
      final last = index == startSteps.length - 1;
      final next = step.answers.where((a) => a.level == null);
      expect(next, hasLength(last ? 0 : 1));
    }
  });

  test('cada color START tiene su resumen', () {
    for (final level in TriageLevel.startLevels) {
      expect(startResultSummary(level), isNotEmpty);
    }
  });
}
