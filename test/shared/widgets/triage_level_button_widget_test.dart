import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double width = 165, double textScale = 1}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(TriageLevelButton),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('START: textos de Figma para sus cuatro colores', (tester) async {
    const expected = {
      TriageLevel.red: ('ROJO', 'Inmediato', 'No camina · no responde'),
      TriageLevel.yellow: ('AMARILLO', 'Urgente', 'Puede esperar atención'),
      TriageLevel.green: ('VERDE', 'Leve', 'Camina por sí mismo'),
      TriageLevel.black: ('NEGRO', 'Fallecido', 'Sin signos vitales'),
    };
    expect(expected.keys, unorderedEquals(TriageLevel.startLevels));

    for (final MapEntry(key: level, value: texts) in expected.entries) {
      await tester.pumpWidget(
        _wrap(TriageLevelButton.start(level, selected: false, onTap: () {})),
      );
      expect(find.text(texts.$1), findsOneWidget);
      expect(find.text(texts.$2), findsOneWidget);
      expect(find.text(texts.$3), findsOneWidget);
    }
  });

  testWidgets('hospital: número, nombre y plazo de cada nivel', (tester) async {
    const expected = [
      ('NIVEL 1 · ROJO', 'Resucitación', 'Atención inmediata'),
      ('NIVEL 2 · NARANJA', 'Emergencia', 'Atender antes de 10 min'),
      ('NIVEL 3 · AMARILLO', 'Urgente', 'Atender antes de 60 min'),
      ('NIVEL 4 · VERDE', 'Poco urgente', 'Atender antes de 2 h'),
      ('NIVEL 5 · AZUL', 'No urgente', 'Consulta general'),
    ];
    for (final (i, level) in TriageLevel.hospitalLevels.indexed) {
      await tester.pumpWidget(
        _wrap(TriageLevelButton.hospital(level, selected: false, onTap: () {})),
      );
      expect(find.text(expected[i].$1), findsOneWidget);
      expect(find.text(expected[i].$2), findsOneWidget);
      expect(find.text(expected[i].$3), findsOneWidget);
    }
  });

  testWidgets('admite textos propios', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageLevelButton(
          level: TriageLevel.yellow,
          tag: 'CLASIFICACIÓN SUGERIDA',
          title: 'Amarillo',
          detail: 'Puede esperar',
          selected: false,
          onTap: () {},
        ),
      ),
    );
    expect(find.text('CLASIFICACIÓN SUGERIDA'), findsOneWidget);
  });

  test('un color fuera del protocolo no se acepta', () {
    expect(
      () => TriageLevelButton.start(
        TriageLevel.blue,
        selected: false,
        onTap: () {},
      ),
      throwsAssertionError,
    );
    expect(
      () => TriageLevelButton.hospital(
        TriageLevel.black,
        selected: false,
        onTap: () {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('sin seleccionar: color atenuado, sin borde ni palomita', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageLevelButton.start(TriageLevel.red, selected: false, onTap: () {}),
      ),
    );
    final decoration = _decoration(tester);
    expect(decoration.color, TriageLevel.red.color.withValues(alpha: 0.94));
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNull);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('seleccionado: color sólido, borde oscuro, sombra y palomita', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageLevelButton.start(TriageLevel.red, selected: true, onTap: () {}),
      ),
    );
    final decoration = _decoration(tester);
    expect(decoration.color, TriageLevel.red.color);
    final side = (decoration.border! as Border).top;
    expect(side.color, TriageColors.textPrimary);
    expect(side.width, 3);
    expect(decoration.boxShadow, TriageShadows.floating);
    expect(
      tester.widget<TriageIcon>(find.byType(TriageIcon)).asset,
      TriageIcons.checkCircle,
    );
  });

  testWidgets('seleccionar no cambia el tamaño del botón', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageLevelButton.start(TriageLevel.red, selected: false, onTap: () {}),
      ),
    );
    final idle = tester.getSize(find.byType(TriageLevelButton));

    await tester.pumpWidget(
      _wrap(
        TriageLevelButton.start(TriageLevel.red, selected: true, onTap: () {}),
      ),
    );
    expect(tester.getSize(find.byType(TriageLevelButton)), idle);
  });

  testWidgets('alto mínimo de 96 y se ajusta al contenido', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageLevelButton(
          level: TriageLevel.red,
          tag: 'A',
          title: 'B',
          detail: 'C',
          selected: false,
          onTap: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(TriageLevelButton)).height, 96);
  });

  testWidgets('responde al toque', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        TriageLevelButton.start(
          TriageLevel.green,
          selected: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Leve'));
    expect(taps, 1);
  });

  testWidgets('se anuncia como un solo botón con su estado', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageLevelButton.start(TriageLevel.red, selected: true, onTap: () {}),
      ),
    );
    expect(
      tester.getSemantics(find.text('Inmediato')),
      isSemantics(
        label: 'ROJO\nInmediato\nNo camina · no responde',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  test('contraste ≥ 4.5 en todos los niveles, atenuados o sólidos', () {
    for (final level in TriageLevel.values) {
      final idle = Color.alphaBlend(
        level.color.withValues(alpha: 0.94),
        TriageColors.surface,
      );
      expect(
        _contrast(level.onColor, level.color),
        greaterThanOrEqualTo(4.5),
        reason: level.label,
      );
      expect(
        _contrast(level.onColor, idle),
        greaterThanOrEqualTo(4.5),
        reason: level.label,
      );
    }
  });

  testWidgets('con texto al 200 % y ancho estrecho crece sin desbordarse', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SingleChildScrollView(
          child: TriageLevelButton.hospital(
            TriageLevel.orange,
            selected: true,
            onTap: () {},
          ),
        ),
        width: 140,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TriageLevelButton)).height,
      greaterThan(96),
    );
  });
}
