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

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Color _bandColor(WidgetTester tester) => tester
    .widget<Material>(
      find
          .descendant(
            of: find.byType(TriageHomeHeader),
            matching: find.byType(Material),
          )
          .first,
    )
    .color!;

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
  group('TriageHomeHeader', () {
    testWidgets('la banda toma el color del rol', (tester) async {
      await tester.pumpWidget(_app(const TriageHomeHeader(title: 'Carlos')));
      expect(_bandColor(tester), TriageColors.paramedicAccent);

      await tester.pumpWidget(
        _app(
          const TriageHomeHeader(title: 'Carlos'),
          role: TriageRoleTheme.hospital,
        ),
      );
      await tester.pumpAndSettle(); // MaterialApp anima el cambio de tema
      expect(_bandColor(tester), TriageColors.hospitalAccent);
    });

    testWidgets('textos sobre la banda con contraste ≥ 4.5 en ambos roles', (
      tester,
    ) async {
      for (final role in [
        TriageRoleTheme.paramedic,
        TriageRoleTheme.hospital,
      ]) {
        await tester.pumpWidget(
          _app(
            const TriageHomeHeader(
              eyebrow: 'Médico receptor',
              title: 'Carlos Huerta',
              subtitle: 'Hospital General',
            ),
            role: role,
          ),
        );
        for (final text in [
          'Médico receptor',
          'Carlos Huerta',
          'Hospital General',
        ]) {
          final color = tester.widget<Text>(find.text(text)).style!.color!;
          expect(
            _contrast(color, role.accent),
            greaterThanOrEqualTo(4.5),
            reason: '"$text" sobre ${role.accent}',
          );
        }
      }
    });

    testWidgets('sin callbacks no muestra avatar ni campana', (tester) async {
      await tester.pumpWidget(_app(const TriageHomeHeader(title: 'Sala')));
      expect(find.byTooltip('Perfil'), findsNothing);
      expect(find.byTooltip('Notificaciones'), findsNothing);
    });

    testWidgets('avatar y campana responden con zona táctil de 48', (
      tester,
    ) async {
      var profile = 0, notifications = 0;
      await tester.pumpWidget(
        _app(
          TriageHomeHeader(
            title: 'Carlos',
            onProfileTap: () => profile++,
            onNotificationsTap: () => notifications++,
          ),
        ),
      );
      expect(tester.getSize(find.byTooltip('Perfil')), const Size(48, 48));
      expect(
        tester.getSize(find.byTooltip('Notificaciones')),
        const Size(48, 48),
      );
      await tester.tap(find.byTooltip('Perfil'));
      await tester.tap(find.byTooltip('Notificaciones'));
      expect((profile, notifications), (1, 1));
    });

    testWidgets('punto de avisos visible y anunciado', (tester) async {
      await tester.pumpWidget(
        _app(
          TriageHomeHeader(
            title: 'Carlos',
            onNotificationsTap: () {},
            hasNotifications: true,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('triage-header-dot')), findsOneWidget);
      expect(
        find.byTooltip('Notificaciones, hay avisos nuevos'),
        findsOneWidget,
      );
    });

    testWidgets('muestra el contenido extra dentro de la banda', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const TriageHomeHeader(title: 'Carlos', bottom: Text('Métricas'))),
      );
      expect(
        find.descendant(
          of: find.byType(TriageHomeHeader),
          matching: find.text('Métricas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'título anunciado como encabezado e íconos del sistema claros',
      (tester) async {
        await tester.pumpWidget(_app(const TriageHomeHeader(title: 'Carlos')));
        expect(
          tester.getSemantics(find.text('Carlos')),
          isSemantics(label: 'Carlos', isHeader: true),
        );
        expect(_overlay(tester, TriageHomeHeader), SystemUiOverlayStyle.light);
      },
    );

    testWidgets('con texto al 200 % en pantalla de 320 crece sin desbordarse', (
      tester,
    ) async {
      _narrowScreen(tester);
      Widget header() => TriageHomeHeader(
        eyebrow: 'Paramédico en turno',
        title: 'Carlos Huerta Domínguez',
        subtitle: 'Unidad A-12 · Tijuana',
        onProfileTap: () {},
        onNotificationsTap: () {},
      );
      await tester.pumpWidget(_app(header()));
      final normal = tester.getSize(find.byType(TriageHomeHeader)).height;

      await tester.pumpWidget(_app(header(), textScale: 2));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TriageHomeHeader)).height,
        greaterThan(normal),
      );
    });
  });

  group('TriageDetailHeader', () {
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
