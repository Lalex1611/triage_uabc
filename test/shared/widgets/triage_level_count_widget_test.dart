import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double width = 400}) => MaterialApp(
  home: Center(
    child: SizedBox(width: width, child: child),
  ),
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('un cuadro por nivel START; los ausentes cuentan 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TriageLevelCount(
          counts: {TriageLevel.red: 3, TriageLevel.green: 1},
        ),
      ),
    );
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(texts, ['3', '0', '1', '0']);
  });

  testWidgets('números con contraste ≥ 4.5 sobre su color', (tester) async {
    final counts = {for (final l in TriageLevel.values) l: l.index + 1};
    await tester.pumpWidget(
      _wrap(TriageLevelCount(counts: counts, levels: TriageLevel.values)),
    );
    for (final level in TriageLevel.values) {
      final text = tester.widget<Text>(find.text('${counts[level]}'));
      expect(
        _contrast(text.style!.color!, level.color),
        greaterThanOrEqualTo(4.5),
        reason: level.label,
      );
    }
  });

  testWidgets('se anuncia como una sola frase', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageLevelCount(counts: {TriageLevel.red: 3})),
    );
    expect(
      tester.getSemantics(find.byType(TriageLevelCount)),
      isSemantics(label: 'Rojo: 3, Amarillo: 0, Verde: 0, Negro: 0'),
    );
  });

  testWidgets('cuadro mínimo de 30×26 que crece con dos cifras', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const TriageLevelCount(counts: {TriageLevel.red: 12})),
    );
    Size box(String n) => tester.getSize(
      find.ancestor(of: find.text(n), matching: find.byType(Container)).first,
    );
    expect(box('0'), const Size(30, 26));
    expect(box('12').width, greaterThan(30));
  });

  testWidgets('en un ancho angosto pasa a otra línea sin desbordarse', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const TriageLevelCount(counts: {}), width: 80),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TriageLevelCount)).height,
      greaterThan(26),
    );
  });
}
