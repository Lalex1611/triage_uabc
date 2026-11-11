import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_protocol.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Recorre el protocolo con las respuestas indicadas (0 o 1 por paso)
TriageLevel? _run(List<int> choices) {
  for (final (step, choice) in choices.indexed) {
    final level = startSteps[step].answers[choice].level;
    if (level != null) return level;
  }
  return null;
}

void main() {
  test('cada camino del protocolo termina en el color de START', () {
    expect(_run([0]), TriageLevel.green); // camina
    expect(_run([1, 0]), TriageLevel.black); // no respira ni al abrir la vía
    expect(_run([1, 1, 0]), TriageLevel.red); // más de 30 por minuto
    expect(_run([1, 1, 1, 0]), TriageLevel.red); // llenado mayor a 2 s
    expect(_run([1, 1, 1, 1, 0]), TriageLevel.red); // no obedece
    expect(_run([1, 1, 1, 1, 1]), TriageLevel.yellow); // obedece
  });

  test('solo la última pregunta clasifica con sus dos respuestas', () {
    for (final (index, step) in startSteps.indexed) {
      expect(step.answers, hasLength(2));
      final classifying = step.answers.where((a) => a.level != null).length;
      expect(classifying, index == startSteps.length - 1 ? 2 : 1);
    }
  });

  test('cada color START tiene su resumen', () {
    for (final level in TriageLevel.startLevels) {
      expect(startResultSummary(level), isNotEmpty);
    }
  });
}
