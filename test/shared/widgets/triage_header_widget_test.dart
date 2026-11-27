import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _app(Widget header, {TriageRoleTheme? role, double textScale = 1}) =>
    MaterialApp(
      theme: ThemeData(extensions: [?role]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            header,
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );

SystemUiOverlayStyle _overlay(WidgetTester tester, Type header) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.descendant(
        of: find.byType(header),
        matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      ),
    )
    .value;

/// Pantalla de 320 de ancho (teléfono pequeño)
void _narrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(960, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('TriageDetailHeader', () {
    testWidgets('con insignia, el título es discreto y va junto a ella', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const TriageDetailHeader(
            title: 'INC-729',
            badge: TriageStatusBadge.active(),
          ),
        ),
      );
      expect(find.text('ACTIVO'), findsOneWidget);
      final title = tester.widget<Text>(find.text('INC-729')).style!;
      expect(title.fontSize, TriageTextStyles.labelMedium.fontSize);
      expect(title.color, TriageColors.textSecondary);
      expect(
        tester.getSemantics(find.text('INC-729')),
        isSemantics(label: 'INC-729', isHeader: true),
      );
      expect(
        tester.getCenter(find.text('INC-729')).dy,
        closeTo(tester.getCenter(find.text('ACTIVO')).dy, 1),
      );
    });

    testWidgets('showDivider decide si hay línea inferior', (tester) async {
      await tester.pumpWidget(_app(const TriageDetailHeader(title: 'A')));
      expect(find.byType(Divider), findsOneWidget);

      await tester.pumpWidget(
        _app(const TriageDetailHeader(title: 'A', showDivider: false)),
      );
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('línea superior con el color del rol', (tester) async {
      await tester.pumpWidget(
        _app(
          const TriageDetailHeader(title: 'PAC-2031'),
          role: TriageRoleTheme.hospital,
        ),
      );
      final line = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(TriageDetailHeader),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(line.color, TriageColors.hospitalAccent);
    });

    testWidgets(
      'en la ruta inicial no hay flecha; al abrir otra aparece y regresa',
      (tester) async {
        await tester.pumpWidget(
          _app(const TriageDetailHeader(title: 'Inicio')),
        );
        expect(find.byTooltip('Regresar'), findsNothing);

        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  body: Column(
                    children: [TriageDetailHeader(title: 'Detalle')],
                  ),
                ),
              ),
            );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Regresar'), findsOneWidget);

        await tester.tap(find.byTooltip('Regresar'));
        await tester.pumpAndSettle();
        expect(find.text('Detalle'), findsNothing);
      },
    );

    testWidgets('onBack y onMore propios con zona táctil de 48', (
      tester,
    ) async {
      var back = 0, more = 0;
      await tester.pumpWidget(
        _app(
          TriageDetailHeader(
            title: 'PAC-2031',
            onBack: () => back++,
            onMore: () => more++,
          ),
        ),
      );
      expect(tester.getSize(find.byTooltip('Regresar')), const Size(48, 48));
      expect(
        tester.getSize(find.byTooltip('Más opciones')),
        const Size(48, 48),
      );
      await tester.tap(find.byTooltip('Regresar'));
      await tester.tap(find.byTooltip('Más opciones'));
      expect((back, more), (1, 1));
    });

    testWidgets('título y subtítulo largos no se cortan', (tester) async {
      _narrowScreen(tester);
      const title = 'Paciente con un nombre bastante largo de registrar';
      await tester.pumpWidget(
        _app(
          TriageDetailHeader(
            title: title,
            subtitle: 'Bruce Cervantes Hernández · INC-729 · Choque múltiple',
            onBack: () {},
            onMore: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(title));
      expect(text.maxLines, isNull);
      expect(tester.getSize(find.text(title)).height, greaterThan(24));
    });

    testWidgets('useCloseIcon muestra una X que llama a onBack', (
      tester,
    ) async {
      var back = 0;
      await tester.pumpWidget(
        _app(
          TriageDetailHeader(
            title: 'Confirmar recepción',
            useCloseIcon: true,
            onBack: () => back++,
          ),
        ),
      );
      expect(find.byTooltip('Regresar'), findsNothing);
      expect(
        tester
            .widget<TriageIcon>(
              find.descendant(
                of: find.byTooltip('Cerrar'),
                matching: find.byType(TriageIcon),
              ),
            )
            .asset,
        TriageIcons.close,
      );
      await tester.tap(find.byTooltip('Cerrar'));
      expect(back, 1);
    });

    testWidgets('sin onMore no muestra "más opciones"', (tester) async {
      await tester.pumpWidget(_app(const TriageDetailHeader(title: 'PAC')));
      expect(find.byTooltip('Más opciones'), findsNothing);
    });

    testWidgets(
      'título como encabezado, subtítulo e íconos del sistema oscuros',
      (tester) async {
        await tester.pumpWidget(
          _app(
            const TriageDetailHeader(
              title: 'PAC-2031',
              subtitle: 'Bruce Cervantes · INC-729',
            ),
          ),
        );
        expect(find.text('Bruce Cervantes · INC-729'), findsOneWidget);
        expect(
          tester.getSemantics(find.text('PAC-2031')),
          isSemantics(label: 'PAC-2031', isHeader: true),
        );
        expect(_overlay(tester, TriageDetailHeader), SystemUiOverlayStyle.dark);
      },
    );

    testWidgets('con texto al 200 % en pantalla de 320 crece sin desbordarse', (
      tester,
    ) async {
      _narrowScreen(tester);
      Widget header() => TriageDetailHeader(
        title: 'PAC-2031',
        subtitle: 'Bruce Cervantes · INC-729',
        onBack: () {},
        onMore: () {},
      );
      await tester.pumpWidget(_app(header()));
      final normal = tester.getSize(find.byType(TriageDetailHeader)).height;

      await tester.pumpWidget(_app(header(), textScale: 2));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TriageDetailHeader)).height,
        greaterThan(normal),
      );
    });
  });
}
