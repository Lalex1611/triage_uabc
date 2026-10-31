import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child) => MaterialApp(home: Center(child: child));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('nombre del nivel en mayúsculas con contraste ≥ 4.5', (
    tester,
  ) async {
    for (final level in TriageLevel.values) {
      await tester.pumpWidget(_wrap(TriageLevelPill(level)));
      final text = tester.widget<Text>(find.text(level.label.toUpperCase()));
      expect(
        _contrast(text.style!.color!, level.color),
        greaterThanOrEqualTo(4.5),
        reason: level.label,
      );
    }
  });

  testWidgets('alto mínimo de 28 y fondo del color del nivel', (tester) async {
    await tester.pumpWidget(_wrap(const TriageLevelPill(TriageLevel.red)));
    expect(tester.getSize(find.byType(TriageLevelPill)).height, 28);
    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(TriageLevelPill),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as ShapeDecoration;
    expect(decoration.color, TriageColors.triageRed);
  });

  testWidgets('se anuncia como "Triage Rojo"', (tester) async {
    await tester.pumpWidget(_wrap(const TriageLevelPill(TriageLevel.red)));
    expect(
      tester.getSemantics(find.byType(TriageLevelPill)),
      isSemantics(label: 'Triage Rojo'),
    );
  });
}
