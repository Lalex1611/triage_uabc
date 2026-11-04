import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

final _image = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

Widget _wrap(Widget child, {double width = 104, double textScale = 1}) =>
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

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

final _dashedBorder = find.byWidgetPredicate(
  (w) =>
      w is CustomPaint &&
      w.foregroundPainter.runtimeType.toString() == '_DashedBorderPainter',
);

void main() {
  testWidgets('es cuadrada y ocupa el ancho de su contenedor', (tester) async {
    await tester.pumpWidget(_wrap(const TriagePhoto(), width: 120));
    expect(tester.getSize(find.byType(TriagePhoto)), const Size(120, 120));
  });

  testWidgets('tres en una fila se reparten el ancho', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Row(
          spacing: TriageSpacing.sm,
          children: [
            Expanded(child: TriagePhoto()),
            Expanded(child: TriagePhoto()),
            Expanded(child: TriagePhoto()),
          ],
        ),
        width: 340,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TriagePhoto).first),
      const Size(108, 108),
    );
  });

  testWidgets('vacía: "Añadir" con borde punteado', (tester) async {
    await tester.pumpWidget(_wrap(TriagePhoto(onTap: () {})));
    expect(find.text('Añadir'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(_dashedBorder, findsOneWidget);
  });

  testWidgets('con imagen: la muestra cubriendo el recuadro', (tester) async {
    await tester.pumpWidget(_wrap(TriagePhoto(image: _image)));
    expect(find.text('Añadir'), findsNothing);
    expect(_dashedBorder, findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, _image);
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('responde al toque, vacía o con imagen', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(TriagePhoto(onTap: () => taps++)));
    await tester.tap(find.byType(TriagePhoto));
    await tester.pumpWidget(
      _wrap(TriagePhoto(image: _image, onTap: () => taps++)),
    );
    await tester.tap(find.byType(TriagePhoto));
    expect(taps, 2);
  });

  testWidgets('el lector anuncia qué es y si se puede tocar', (tester) async {
    await tester.pumpWidget(_wrap(TriagePhoto(onTap: () {})));
    expect(
      tester.getSemantics(find.byType(TriagePhoto)),
      isSemantics(
        label: 'Añadir fotografía',
        isButton: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(
      _wrap(TriagePhoto(image: _image, semanticLabel: 'Foto del paciente')),
    );
    expect(
      tester.getSemantics(find.byType(TriagePhoto)),
      isSemantics(label: 'Foto del paciente', isImage: true, isButton: false),
    );
  });

  test('contraste de la etiqueta y de los íconos', () {
    expect(
      _contrast(TriageColors.textSecondary, TriageColors.sunken),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(TriageColors.textSecondary, TriageColors.borderStrong),
      greaterThanOrEqualTo(3),
    );
  });

  testWidgets('estrecha y con texto al 200 % no se desborda', (tester) async {
    await tester.pumpWidget(
      _wrap(TriagePhoto(onTap: () {}), width: 56, textScale: 2),
    );
    expect(tester.takeException(), isNull);
  });
}
