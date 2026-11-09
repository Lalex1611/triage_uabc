import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

void main() {
  for (final level in TriageLevel.values) {
    testWidgets('pinta el color de ${level.label} y lo anuncia', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(TriageLevelBar(level)));
      final bar = tester.widget<Container>(find.byType(Container));
      final decoration = bar.decoration! as BoxDecoration;
      expect(decoration.color, level.color);
      expect(decoration.borderRadius, BorderRadius.circular(TriageRadii.full));
      expect(
        tester.getSemantics(find.byType(TriageLevelBar)),
        isSemantics(label: 'Triage ${level.label}'),
      );
    });
  }

  testWidgets('admite otro ancho y alto mínimo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IntrinsicHeight(
          child: TriageLevelBar(TriageLevel.red, width: 19, minHeight: 48),
        ),
      ),
    );
    expect(tester.getSize(find.byType(TriageLevelBar)), const Size(19, 48));
  });

  testWidgets('crece hasta el alto de su fila', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TriageLevelBar(TriageLevel.red),
              SizedBox(width: 10, height: 120),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(TriageLevelBar)).height, 120);
  });
}
