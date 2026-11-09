import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _opener({
  required WidgetBuilder builder,
  String? title = 'Asignar traslado',
  String? subtitle,
  TriageSteps? steps,
  bool showClose = true,
  bool dismissible = true,
  ValueChanged<String?>? onResult,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          final result = await showTriageSheet<String>(
            context,
            title: title,
            subtitle: subtitle,
            steps: steps,
            showClose: showClose,
            dismissible: dismissible,
            builder: builder,
          );
          onResult?.call(result);
        },
        child: const Text('Abrir'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Widget _body(BuildContext context) => const Text('Contenido');

void main() {
  testWidgets('muestra título, subtítulo, pasos y contenido', (tester) async {
    await tester.pumpWidget(
      _opener(
        subtitle: 'Paso 1 de 3 · seguro médico',
        steps: const TriageSteps(current: 1, total: 3),
        builder: _body,
      ),
    );
    await _open(tester);
    expect(find.text('Asignar traslado'), findsOneWidget);
    expect(find.text('Paso 1 de 3 · seguro médico'), findsOneWidget);
    expect(find.byType(TriageSteps), findsOneWidget);
    expect(find.text('Contenido'), findsOneWidget);
  });

  testWidgets('esquinas de 26, sombra de hoja y agarre de Figma', (
    tester,
  ) async {
    await tester.pumpWidget(_opener(builder: _body));
    await _open(tester);

    final decorated = find.descendant(
      of: find.byType(TriageSheet),
      matching: find.byType(DecoratedBox),
    );
    final surface =
        tester.widget<DecoratedBox>(decorated.first).decoration
            as BoxDecoration;
    expect(surface.boxShadow, TriageShadows.sheet);
    expect(
      surface.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(TriageRadii.xxl)),
    );

    final grip = decorated.at(1);
    expect(
      (tester.widget<DecoratedBox>(grip).decoration as BoxDecoration).color,
      TriageColors.borderStrong,
    );
    expect(tester.getSize(grip), const Size(44, 5));
    expect(
      tester.getCenter(grip).dx,
      tester.getCenter(find.byType(TriageSheet)).dx,
    );
  });

  testWidgets('la X cierra la hoja y tiene zona táctil de 48', (tester) async {
    String? result = 'sin cerrar';
    await tester.pumpWidget(
      _opener(builder: _body, onResult: (value) => result = value),
    );
    await _open(tester);

    final close = find.byTooltip('Cerrar');
    expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(close).width, greaterThanOrEqualTo(48));

    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
    expect(result, isNull);
  });

  testWidgets('devuelve el resultado de Navigator.pop', (tester) async {
    String? result;
    await tester.pumpWidget(
      _opener(
        builder: (context) => TextButton(
          onPressed: () => Navigator.pop(context, 'START guiado'),
          child: const Text('Elegir'),
        ),
        onResult: (value) => result = value,
      ),
    );
    await _open(tester);
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    expect(result, 'START guiado');
  });

  testWidgets('se cierra tocando fuera y arrastrando hacia abajo', (
    tester,
  ) async {
    await tester.pumpWidget(_opener(builder: _body));
    await _open(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);

    await _open(tester);
    await tester.drag(find.text('Asignar traslado'), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
  });

  group('dismissible: false', () {
    testWidgets('no se cierra tocando fuera, arrastrando ni con atrás', (
      tester,
    ) async {
      await tester.pumpWidget(_opener(dismissible: false, builder: _body));
      await _open(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(TriageSheet), findsOneWidget);

      await tester.drag(find.text('Asignar traslado'), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.byType(TriageSheet), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TriageSheet), findsOneWidget);
    });

    testWidgets('la X sigue cerrando', (tester) async {
      await tester.pumpWidget(_opener(dismissible: false, builder: _body));
      await _open(tester);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(TriageSheet), findsNothing);
    });

    testWidgets('Navigator.pop devuelve el resultado', (tester) async {
      String? result;
      await tester.pumpWidget(
        _opener(
          dismissible: false,
          showClose: false,
          builder: (context) => TextButton(
            onPressed: () => Navigator.pop(context, 'Guardado'),
            child: const Text('Guardar'),
          ),
          onResult: (value) => result = value,
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(result, 'Guardado');
    });

    testWidgets('oculta el agarre, que invita a arrastrar', (tester) async {
      await tester.pumpWidget(_opener(dismissible: false, builder: _body));
      await _open(tester);
      expect(
        tester
            .widget<Visibility>(
              find.descendant(
                of: find.byType(TriageSheet),
                matching: find.byType(Visibility),
              ),
            )
            .visible,
        isFalse,
      );
    });
  });

  testWidgets('sin X no hay botón ni línea bajo la cabecera', (tester) async {
    await tester.pumpWidget(_opener(showClose: false, builder: _body));
    await _open(tester);
    expect(find.byTooltip('Cerrar'), findsNothing);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('sin título sigue mostrando la X y cierra', (tester) async {
    await tester.pumpWidget(_opener(title: null, builder: _body));
    await _open(tester);
    expect(find.byType(Divider), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
  });

  testWidgets('sin título ni X sigue mostrando el subtítulo', (tester) async {
    await tester.pumpWidget(
      _opener(
        title: null,
        subtitle: 'INC-729',
        showClose: false,
        builder: _body,
      ),
    );
    await _open(tester);
    expect(find.text('INC-729'), findsOneWidget);
  });

  testWidgets('con X hay línea bajo la cabecera', (tester) async {
    await tester.pumpWidget(_opener(builder: _body));
    await _open(tester);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('el título se anuncia como encabezado', (tester) async {
    await tester.pumpWidget(_opener(builder: _body));
    await _open(tester);
    expect(
      tester.getSemantics(find.text('Asignar traslado')),
      isSemantics(label: 'Asignar traslado', isHeader: true),
    );
  });

  testWidgets('sube con el teclado', (tester) async {
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_opener(builder: _body));
    await _open(tester);
    final closedBottom = tester.getBottomLeft(find.byType(TriageSheet)).dy;

    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(TriageSheet)).dy,
      closedBottom - 300,
    );
  });

  testWidgets('contenido largo y texto al 200 %: se desplaza sin desbordarse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _opener(
        subtitle: 'Paso 1 de 3 · seguro médico',
        textScale: 2,
        builder: (_) => Column(
          children: [
            for (var i = 0; i < 30; i++) Text('Fila $i'),
            const Text('Última fila'),
          ],
        ),
      ),
    );
    await _open(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Última fila').hitTestable(), findsNothing);

    await tester.drag(find.text('Fila 3'), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Última fila').hitTestable(), findsOneWidget);
  });

  testWidgets('hoja fija: admite una lista como contenido', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 300,
              child: TriageSheet(
                title: 'Incidentes activos',
                child: ListView(
                  children: [for (var i = 0; i < 50; i++) Text('Incidente $i')],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Incidente 0'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsNothing);
  });
}
