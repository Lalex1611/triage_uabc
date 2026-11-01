import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double width = 360, double textScale = 1}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  testWidgets('concepto a la izquierda y valor a la derecha', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageDataRow(label: 'Edad', value: '34 años')),
    );
    final row = tester.getRect(find.byType(TriageDataRow));
    expect(tester.getTopLeft(find.text('Edad')).dx, row.left);
    expect(tester.getTopRight(find.text('34 años')).dx, row.right);
    expect(find.byType(TriageIcon), findsNothing);
  });

  testWidgets('sin valor ni toque solo muestra el concepto', (tester) async {
    await tester.pumpWidget(_wrap(const TriageDataRow(label: 'Alergias')));
    expect(find.byType(Text), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('con onTap: chevron, botón de 48 y responde al toque', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        TriageDataRow(label: 'Hospital', value: 'General', onTap: () => taps++),
      ),
    );
    expect(find.byType(TriageIcon), findsOneWidget);
    expect(
      tester.getSize(find.byType(TriageDataRow)).height,
      greaterThanOrEqualTo(TriageSizes.touchTarget),
    );
    expect(
      tester.getSemantics(find.text('Hospital')),
      isSemantics(label: 'Hospital\nGeneral', isButton: true),
    );
    await tester.tap(find.byType(TriageDataRow));
    expect(taps, 1);
  });

  testWidgets('si no cabe, el valor baja de línea sin desbordarse', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TriageDataRow(
          label: 'Mecanismo de lesión',
          value: 'Impacto lateral a alta velocidad',
        ),
        width: 320,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.textContaining('Impacto')).dy,
      greaterThan(tester.getBottomLeft(find.text('Mecanismo de lesión')).dy),
    );
  });
}
