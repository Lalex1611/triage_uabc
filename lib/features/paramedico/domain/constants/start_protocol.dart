import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Respuesta a una pregunta del protocolo START
///
/// Con [level] clasifica al paciente; sin él, sigue a la siguiente pregunta.
class StartAnswer {
  const StartAnswer({required this.label, required this.reason, this.level});

  final String label;

  /// Valor en «Por qué salió…» (p. ej. «No» junto a «Camina por sí mismo»)
  final String reason;
  final TriageLevel? level;
}

/// Pregunta del protocolo START, con sus respuestas
class StartStep {
  const StartStep({
    required this.question,
    required this.hint,
    required this.concept,
    required this.answers,
  });

  final String question;
  final String hint;

  /// Concepto en «Por qué salió…» (p. ej. «Respira»)
  final String concept;
  final List<StartAnswer> answers;
}

/// Protocolo START en el orden en que se pregunta
///
/// La última pregunta clasifica con cualquiera de sus respuestas. Si el
/// paciente solo respira tras abrir la vía aérea es rojo; si no respira ni así,
/// negro. Solo quien respira por sí mismo sigue al paso 3.
const startSteps = [
  StartStep(
    question: '¿El paciente camina por sí mismo?',
    hint: 'Pídele que se mueva hacia un punto seguro. Si camina, es leve.',
    concept: 'Camina por sí mismo',
    answers: [
      StartAnswer(label: 'Sí, camina', reason: 'Sí', level: TriageLevel.green),
      StartAnswer(label: 'No camina', reason: 'No'),
    ],
  ),
  StartStep(
    question: '¿Respira?',
    hint:
        'Si no respira, abre la vía aérea y vuelve a revisar antes de '
        'responder.',
    concept: 'Respira',
    answers: [
      StartAnswer(
        label: 'No respira ni al abrir la vía aérea',
        reason: 'No, ni al abrir la vía aérea',
        level: TriageLevel.black,
      ),
      StartAnswer(
        label: 'Respira solo al abrir la vía aérea',
        reason: 'Solo al abrir la vía aérea',
        level: TriageLevel.red,
      ),
      StartAnswer(label: 'Sí respira', reason: 'Sí'),
    ],
  ),
  StartStep(
    question: '¿Cuántas respiraciones por minuto?',
    hint: 'Cuenta 15 segundos y multiplica por cuatro.',
    concept: 'Frecuencia respiratoria',
    answers: [
      StartAnswer(
        label: 'Más de 30 por minuto',
        reason: 'Más de 30 por minuto',
        level: TriageLevel.red,
      ),
      StartAnswer(label: '30 o menos', reason: '30 o menos por minuto'),
    ],
  ),
  StartStep(
    question: '¿Cómo está la circulación?',
    hint: 'Revisa el llenado capilar en la uña o busca pulso radial.',
    concept: 'Llenado capilar',
    answers: [
      StartAnswer(
        label: 'Llenado mayor a 2 s o sin pulso radial',
        reason: 'Mayor a 2 s o sin pulso',
        level: TriageLevel.red,
      ),
      StartAnswer(label: 'Llenado de 2 s o menos', reason: '2 s o menos'),
    ],
  ),
  StartStep(
    question: '¿Obedece órdenes simples?',
    hint: 'Pídele algo concreto: “aprieta mi mano”, “abre los ojos”.',
    concept: 'Obedece órdenes',
    answers: [
      StartAnswer(label: 'No obedece', reason: 'No', level: TriageLevel.red),
      StartAnswer(label: 'Sí obedece', reason: 'Sí', level: TriageLevel.yellow),
    ],
  ),
];

/// Qué implica cada color en el resultado de START guiado
String startResultSummary(TriageLevel level) => switch (level) {
  TriageLevel.red => 'Necesita atención y traslado inmediatos.',
  TriageLevel.yellow => 'Puede esperar atención, pero requiere traslado.',
  TriageLevel.green => 'Lesiones leves: puede esperar en la zona segura.',
  TriageLevel.black => 'Sin respiración tras abrir la vía aérea.',
  TriageLevel.orange || TriageLevel.blue => '',
};
