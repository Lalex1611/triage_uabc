import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(
  Widget child, {
  double width = 353,
  double textScale = 1,
  TriageRoleTheme role = TriageRoleTheme.hospital,
}) => MaterialApp(
  theme: ThemeData(extensions: [role]),
  home: MediaQuery(
    data: MediaQueryData(
      size: Size(width, 800),
      textScaler: TextScaler.linear(textScale),
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

TriagePatientBanner _banner({
  TriageLevel level = TriageLevel.red,
  String? detail,
  String? arrival,
  VoidCallback? onEdit,
}) => TriagePatientBanner(
  level: level,
  tag: 'ROJO · INMEDIATO',
  title: 'Alberto Pérez, 34 años',
  detail: detail,
  arrival: arrival,
  onEdit: onEdit,
);

TriageIncomingCard _incoming({
  VoidCallback? onOpen,
  VoidCallback? onReject,
  VoidCallback? onAccept,
  String name = 'Alberto Pérez',
  TriageLevel level = TriageLevel.red,
}) => TriageIncomingCard(
  level: level,
  name: name,
  detail: 'PAC-2031 · INC-729 · Carlos Huerta',
  arrival: 'Unidad A-12 · llega en 6 min',
  onOpen: onOpen ?? () {},
  onReject: onReject ?? () {},
  onAccept: onAccept ?? () {},
);

void main() {
  group('TriagePatientBanner', () {
    for (final level in TriageLevel.values) {
      testWidgets('nivel ${level.label}: fondo y texto legible', (
        tester,
      ) async {
        await tester.pumpWidget(_wrap(_banner(level: level)));
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(TriagePatientBanner),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((box.decoration as BoxDecoration).color, level.color);
        expect(
          tester.widget<Text>(find.text('Alberto Pérez, 34 años')).style!.color,
          level.onColor,
        );
      });

      testWidgets('nivel ${level.label}: la franja de llegada llega a 4.5:1', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(_banner(level: level, arrival: 'Llega en 6 minutos')),
        );
        final strip = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(TriagePatientBanner),
                matching: find.byType(DecoratedBox),
              )
              .last,
        );
        final background = Color.alphaBlend(
          (strip.decoration as BoxDecoration).color!,
          level.color,
        );
        final text = tester
            .widget<Text>(find.text('Llega en 6 minutos'))
            .style!
            .color!;
        expect(_contrast(text, background), greaterThanOrEqualTo(4.5));
      });
    }

    testWidgets('el título se anuncia como encabezado', (tester) async {
      await tester.pumpWidget(_wrap(_banner()));
      expect(
        tester.getSemantics(find.text('Alberto Pérez, 34 años')),
        isSemantics(label: 'Alberto Pérez, 34 años', isHeader: true),
      );
    });

    testWidgets('sin onEdit ni arrival solo muestra los textos', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_banner(detail: 'Recibido a las 14:52')));
      expect(find.text('Recibido a las 14:52'), findsOneWidget);
      expect(find.byType(TriageIconButton), findsNothing);
      expect(find.byType(TriageIcon), findsNothing);
    });

    testWidgets('el botón de editar responde y tiene zona táctil de 48', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(_banner(onEdit: () => taps++)));
      final button = find.byTooltip('Cambiar clasificación');
      expect(tester.getSize(button), const Size(48, 48));
      await tester.tap(button);
      expect(taps, 1);
    });

    testWidgets('texto al 200 % en 280: crece sin desbordarse', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _banner(
            detail: 'Clasificado por START guiado a las 14:34',
            arrival: 'Llega en 6 minutos · Unidad A-12',
            onEdit: () {},
          ),
          width: 280,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('TriagePatientStrip', () {
    Widget strip(TriageLevel level, {double scale = 1, double width = 353}) =>
        _wrap(
          TriagePatientStrip(
            level: level,
            name: 'Bruce Cervantes · PAC-2031',
            detail: 'Rojo · inmediato · hemorragia en muslo',
          ),
          textScale: scale,
          width: width,
        );

    BoxDecoration decoration(WidgetTester tester) =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(TriagePatientStrip),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    testWidgets('fondo tenue del nivel y barra de color', (tester) async {
      await tester.pumpWidget(strip(TriageLevel.red));
      expect(decoration(tester).color, TriageLevel.red.background);
      expect(find.byType(TriageLevelBar), findsOneWidget);
    });

    testWidgets('niveles sin fondo tenue usan gris', (tester) async {
      await tester.pumpWidget(strip(TriageLevel.orange));
      expect(decoration(tester).color, TriageColors.sunken);
    });

    testWidgets('el lector anuncia nivel, nombre y detalle juntos', (
      tester,
    ) async {
      await tester.pumpWidget(strip(TriageLevel.red));
      final label = tester
          .getSemantics(find.byType(TriageLevelBar))
          .getSemanticsData()
          .label;
      expect(label, contains('Triage Rojo'));
      expect(label, contains('Bruce Cervantes'));
    });

    testWidgets('texto al 200 % en 280: sin desbordes', (tester) async {
      await tester.pumpWidget(strip(TriageLevel.red, scale: 2, width: 280));
      expect(tester.takeException(), isNull);
    });
  });

  group('TriageIncomingCard', () {
    testWidgets('muestra datos, pastilla, llegada y acciones', (tester) async {
      await tester.pumpWidget(_wrap(_incoming()));
      expect(find.text('Alberto Pérez'), findsOneWidget);
      expect(find.text('ROJO'), findsOneWidget);
      expect(find.text('Unidad A-12 · llega en 6 min'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Revisar y aceptar'), findsOneWidget);
    });

    testWidgets('cada zona llama a su acción', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _wrap(
          _incoming(
            onOpen: () => calls.add('abrir'),
            onReject: () => calls.add('rechazar'),
            onAccept: () => calls.add('aceptar'),
          ),
        ),
      );
      await tester.tap(find.text('Alberto Pérez'));
      await tester.tap(find.text('Rechazar'));
      await tester.tap(find.text('Revisar y aceptar'));
      expect(calls, ['abrir', 'rechazar', 'aceptar']);
    });

    testWidgets('los botones se anuncian aparte de la tarjeta', (tester) async {
      await tester.pumpWidget(_wrap(_incoming()));
      final card = tester
          .getSemantics(find.byType(TriageTapCard))
          .getSemanticsData()
          .label;
      expect(card, contains('Alberto Pérez'));
      expect(card, isNot(contains('Rechazar')));
      expect(
        tester.getSemantics(find.text('Rechazar')),
        isSemantics(label: 'Rechazar', isButton: true),
      );
    });

    for (final role in [TriageRoleTheme.paramedic, TriageRoleTheme.hospital]) {
      testWidgets('la llegada usa el rol y llega a 4.5:1', (tester) async {
        await tester.pumpWidget(_wrap(_incoming(), role: role));
        expect(
          tester
              .widget<Text>(find.text('Unidad A-12 · llega en 6 min'))
              .style!
              .color,
          role.accent,
        );
        expect(_contrast(role.accent, role.soft), greaterThanOrEqualTo(4.5));
      });
    }

    testWidgets('la barra mide lo mismo que su fila', (tester) async {
      await tester.pumpWidget(_wrap(_incoming()));
      expect(
        tester.getSize(find.byType(TriageLevelBar)).height,
        greaterThanOrEqualTo(40),
      );
    });

    testWidgets('botones iguales en alto y sin desbordes al 200 % en 280', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _incoming(
            name: 'Paciente sin identificar con nombre largo',
            level: TriageLevel.yellow,
          ),
          width: 280,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TriageButton).first).height,
        tester.getSize(find.byType(TriageButton).last).height,
      );
    });
  });
}
