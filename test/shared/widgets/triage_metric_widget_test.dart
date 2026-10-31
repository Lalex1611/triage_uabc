import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {TriageRoleTheme? role}) => MaterialApp(
  theme: ThemeData(extensions: [?role]),
  home: Center(child: SizedBox(width: 120, child: child)),
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Color _background(WidgetTester tester) =>
    (tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(TriageMetric),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration)
        .color!;

Color _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  testWidgets('neutra: fondo hundido y número primario', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageMetric(value: '7', label: 'En sala')),
    );
    expect(_background(tester), TriageColors.sunken);
    expect(_color(tester, '7'), TriageColors.textPrimary);
  });

  testWidgets('por rol toma el color suave y el acento del rol', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TriageMetric.role(value: '2', label: 'En camino'),
        role: TriageRoleTheme.hospital,
      ),
    );
    expect(_background(tester), TriageColors.hospitalSoft);
    expect(_color(tester, '2'), TriageColors.hospitalAccent);
  });

  testWidgets('todos los tonos: número ≥ 3:1 (texto grande) y etiqueta ≥ 4.5', (
    tester,
  ) async {
    final metrics = <Widget>[
      const TriageMetric(value: '1', label: 'Neutra'),
      for (final level in TriageLevel.startLevels)
        TriageMetric.level(level, value: '1', label: 'Nivel'),
      const TriageMetric.role(value: '1', label: 'Rol'),
    ];
    for (final role in [TriageRoleTheme.paramedic, TriageRoleTheme.hospital]) {
      for (final metric in metrics) {
        await tester.pumpWidget(_wrap(metric, role: role));
        await tester.pumpAndSettle();
        final background = _background(tester);
        final label = tester.widgetList<Text>(find.byType(Text)).last;
        expect(
          _contrast(_color(tester, '1'), background),
          greaterThanOrEqualTo(3),
          reason: '$metric número',
        );
        expect(
          _contrast(label.style!.color!, background),
          greaterThanOrEqualTo(4.5),
          reason: '$metric etiqueta',
        );
      }
    }
  });

  testWidgets('alto mínimo de 74 y se anuncia "etiqueta: valor"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const TriageMetric(value: '2', label: 'Críticos')),
    );
    expect(tester.getSize(find.byType(TriageMetric)).height, 74);
    expect(
      tester.getSemantics(find.byType(TriageMetric)),
      isSemantics(label: 'Críticos: 2'),
    );
  });

  test('naranja y azul no tienen tono de métrica en Figma', () {
    expect(
      () => TriageMetric.level(TriageLevel.orange, value: '1', label: 'x'),
      throwsAssertionError,
    );
  });
}
