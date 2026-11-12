import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(TriageRoleTheme role, Widget child) => MaterialApp(
  theme: ThemeData(extensions: [role]),
  home: Scaffold(body: SizedBox(width: 300, child: child)),
);

List<Color> _barColors(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((box) => (box.decoration as BoxDecoration).color!)
    .toList();

void main() {
  for (final (name, role) in [
    ('campo', TriageRoleTheme.paramedic),
    ('hospital', TriageRoleTheme.hospital),
  ]) {
    testWidgets('hecho, actual y pendiente con el color del rol $name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(role, const TriageSteps(current: 2, total: 3)),
      );
      expect(_barColors(tester), [
        role.accent.withValues(alpha: 0.45),
        role.accent,
        TriageColors.borderMedium,
      ]);
    });
  }

  testWidgets('las barras reparten el ancho y miden 6 de alto', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageRoleTheme.paramedic, const TriageSteps(current: 1, total: 5)),
    );
    final bars = find.byType(DecoratedBox);
    expect(bars, findsNWidgets(5));
    final first = tester.getSize(bars.first);
    expect(first.height, 6);
    expect(first.width, (300 - 4 * TriageSpacing.xs) / 5);
    expect(tester.getSize(bars.last), first);
  });

  testWidgets('anuncia el paso al lector de pantalla', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageRoleTheme.paramedic, const TriageSteps(current: 2, total: 3)),
    );
    expect(find.bySemanticsLabel('Paso 2 de 3'), findsOneWidget);
  });

  testWidgets('con showLabel lo escribe bajo las barras y lo anuncia una vez', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageRoleTheme.paramedic,
        const TriageSteps(current: 3, total: 5, showLabel: true),
      ),
    );
    expect(find.text('Paso 3 de 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Paso 3 de 5'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Paso 3 de 5')).dy,
      greaterThan(tester.getBottomLeft(find.byType(DecoratedBox).first).dy),
    );
  });

  testWidgets('rechaza un paso fuera de rango', (tester) async {
    expect(() => TriageSteps(current: 0, total: 3), throwsAssertionError);
    expect(() => TriageSteps(current: 4, total: 3), throwsAssertionError);
  });
}
