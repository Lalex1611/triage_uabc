import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

const _deleteIcon = TriageMessageIcon(
  TriageIcons.trash,
  tone: TriageTone.danger,
);

Widget _app(Widget home, {TriageRoleTheme? role, double textScale = 1}) =>
    MaterialApp(
      theme: ThemeData(extensions: [?role]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: home),
    );

Widget _opener(Future<void> Function(BuildContext) onOpen) => Builder(
  builder: (context) =>
      TextButton(onPressed: () => onOpen(context), child: const Text('Abrir')),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Widget _dialog({TriageMessageIcon icon = _deleteIcon, Widget? content}) =>
    TriageDialog(
      icon: icon,
      title: '¿Eliminar esta fotografía?',
      message: 'No se puede recuperar.',
      content: content,
      actions: [
        TriageButton(label: 'Eliminar', onPressed: () {}),
        TriageButton(label: 'Cancelar', onPressed: () {}),
      ],
    );

/// Caja del ícono destacado
BoxDecoration _badge(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .ancestor(
                    of: find.byType(TriageIcon),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Color _iconColor(WidgetTester tester) =>
    tester.widget<TriageIcon>(find.byType(TriageIcon)).color!;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  group('TriageMessageIcon', () {
    testWidgets('tono de decisión: recuadro con su color', (tester) async {
      await tester.pumpWidget(_app(_dialog()));
      expect(_badge(tester).color, TriageColors.dangerBackground);
      expect(
        _badge(tester).borderRadius,
        BorderRadius.circular(TriageRadii.xl),
      );
      expect(_iconColor(tester), TriageColors.danger);
    });

    testWidgets('éxito: círculo', (tester) async {
      await tester.pumpWidget(
        _app(
          _dialog(
            icon: const TriageMessageIcon(
              TriageIcons.check,
              tone: TriageTone.success,
            ),
          ),
        ),
      );
      expect(
        _badge(tester).borderRadius,
        BorderRadius.circular(TriageRadii.full),
      );
    });

    testWidgets('rol: color del rol activo', (tester) async {
      await tester.pumpWidget(
        _app(
          _dialog(icon: const TriageMessageIcon.role(TriageIcons.checkCircle)),
          role: TriageRoleTheme.hospital,
        ),
      );
      await tester.pumpAndSettle();
      expect(_badge(tester).color, TriageRoleTheme.hospital.soft);
      expect(_iconColor(tester), TriageRoleTheme.hospital.accent);
    });

    testWidgets('nivel: ícono con contraste ≥ 3 en todos los colores', (
      tester,
    ) async {
      for (final level in TriageLevel.values) {
        await tester.pumpWidget(
          _app(
            _dialog(icon: TriageMessageIcon.level(TriageIcons.check, level)),
          ),
        );
        expect(
          _contrast(_iconColor(tester), _badge(tester).color!),
          greaterThanOrEqualTo(3),
          reason: level.label,
        );
      }
    });

    test('tonos y roles con contraste ≥ 3 sobre su fondo', () {
      for (final tone in TriageTone.values) {
        expect(
          _contrast(tone.color, tone.background),
          greaterThanOrEqualTo(3),
          reason: tone.name,
        );
      }
      for (final role in [
        TriageRoleTheme.paramedic,
        TriageRoleTheme.hospital,
      ]) {
        expect(_contrast(role.accent, role.soft), greaterThanOrEqualTo(3));
      }
    });
  });

  group('TriageDialog', () {
    testWidgets('muestra ícono de 64, título, mensaje y contenido', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_dialog(content: const Text('Extra'))));
      expect(find.text('¿Eliminar esta fotografía?'), findsOneWidget);
      expect(find.text('No se puede recuperar.'), findsOneWidget);
      expect(find.text('Extra'), findsOneWidget);
      expect(
        tester.getSize(
          find
              .ancestor(
                of: find.byType(TriageIcon),
                matching: find.byType(DecoratedBox),
              )
              .first,
        ),
        const Size(64, 64),
      );
      expect(tester.widget<TriageIcon>(find.byType(TriageIcon)).size, 32);
    });

    testWidgets('esquinas de 26 y sombra flotante', (tester) async {
      await tester.pumpWidget(_app(_dialog()));
      final panel =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(TriageDialog),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(panel.boxShadow, TriageShadows.floating);
      expect(
        panel.borderRadius,
        const BorderRadius.all(Radius.circular(TriageRadii.xxl)),
      );
    });

    testWidgets('los botones ocupan todo el ancho', (tester) async {
      await tester.pumpWidget(_app(_dialog()));
      final delete = tester.getSize(find.byType(TriageButton).first).width;
      final panel = tester
          .getSize(
            find
                .descendant(
                  of: find.byType(TriageDialog),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .width;
      expect(delete, panel - 2 * TriageSpacing.xxl);
      expect(tester.getSize(find.byType(TriageButton).last).width, delete);
    });

    testWidgets('el título se anuncia como encabezado', (tester) async {
      await tester.pumpWidget(_app(_dialog()));
      expect(
        tester.getSemantics(find.text('¿Eliminar esta fotografía?')),
        isSemantics(
          label: '¿Eliminar esta fotografía?',
          isHeader: true,
          namesRoute: true,
        ),
      );
    });

    testWidgets('en pantalla ancha no pasa de 416', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_dialog()));
      final panel = find
          .descendant(
            of: find.byType(TriageDialog),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(tester.getSize(panel).width, 416);
    });

    testWidgets('con texto al 200 % en pantalla pequeña se desplaza', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_dialog(), textScale: 2));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Cancelar'),
        100,
        scrollable: find.descendant(
          of: find.byType(TriageDialog),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Cancelar').hitTestable(), findsOneWidget);
    });
  });

  group('showTriageConfirm', () {
    Future<bool?> run(
      WidgetTester tester,
      Future<void> Function() act, {
      TriageButtonVariant variant = TriageButtonVariant.primary,
    }) async {
      bool? result;
      await tester.pumpWidget(
        _app(
          _opener((context) async {
            result = await showTriageConfirm(
              context,
              icon: _deleteIcon,
              title: '¿Cerrar el incidente?',
              message: 'Saldrá de la lista de activos.',
              confirmLabel: 'Sí, cerrar',
              confirmVariant: variant,
            );
          }),
        ),
      );
      await _open(tester);
      await act();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('confirmar devuelve true', (tester) async {
      expect(
        await run(tester, () => tester.tap(find.text('Sí, cerrar'))),
        isTrue,
      );
    });

    testWidgets('cancelar devuelve false', (tester) async {
      expect(
        await run(tester, () => tester.tap(find.text('Cancelar'))),
        isFalse,
      );
    });

    testWidgets('tocar fuera devuelve false', (tester) async {
      expect(
        await run(tester, () => tester.tapAt(const Offset(4, 4))),
        isFalse,
      );
    });

    testWidgets('aplica la variante de la confirmación', (tester) async {
      await tester.pumpWidget(
        _app(
          _opener(
            (context) => showTriageConfirm(
              context,
              icon: _deleteIcon,
              title: 'Eliminar',
              confirmLabel: 'Eliminar',
              confirmVariant: TriageButtonVariant.danger,
            ),
          ),
        ),
      );
      await _open(tester);
      final buttons = tester
          .widgetList<TriageButton>(find.byType(TriageButton))
          .toList();
      expect(buttons.first.variant, TriageButtonVariant.danger);
      expect(buttons.last.variant, TriageButtonVariant.subtle);
      expect(buttons.last.size, TriageButtonSize.medium);
    });
  });

  group('TriageResultMessage', () {
    Widget result({
      Widget? content,
      bool prominentTitle = false,
      VoidCallback? onPrimary,
    }) => TriageResultMessage(
      icon: const TriageMessageIcon(
        TriageIcons.check,
        tone: TriageTone.success,
      ),
      title: 'Recepción confirmada',
      message: 'Carlos Huerta ya recibió el aviso.',
      content: content,
      prominentTitle: prominentTitle,
      actions: [
        TriageButton(label: 'Ver en la sala', onPressed: onPrimary ?? () {}),
        TriageButton(
          label: 'Volver a entrantes',
          variant: TriageButtonVariant.subtle,
          size: TriageButtonSize.medium,
          onPressed: () {},
        ),
      ],
    );

    Text title(WidgetTester tester) =>
        tester.widget<Text>(find.text('Recepción confirmada'));

    double iconSize(WidgetTester tester) => tester
        .getSize(
          find
              .ancestor(
                of: find.byType(TriageIcon),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .width;

    void setScreen(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('en móviles estrechos el ícono se reduce', (tester) async {
      setScreen(tester, const Size(320, 800));
      await tester.pumpWidget(_app(result()));
      expect(iconSize(tester), closeTo(88 * 0.82, 0.1));
    });

    testWidgets('en móviles bajos el ícono cede espacio', (tester) async {
      setScreen(tester, const Size(393, 600));
      await tester.pumpWidget(_app(result()));
      expect(iconSize(tester), 64);
    });

    testWidgets('el margen lateral se reduce en pantallas estrechas', (
      tester,
    ) async {
      setScreen(tester, const Size(300, 800));
      await tester.pumpWidget(_app(result()));
      expect(
        tester.getTopLeft(find.byType(TriageButton).first).dx,
        TriageSpacing.md,
      );
    });

    testWidgets('ícono de 88 y título grande por defecto', (tester) async {
      setScreen(tester, const Size(393, 852));
      await tester.pumpWidget(_app(result()));
      expect(
        tester.getSize(
          find
              .ancestor(
                of: find.byType(TriageIcon),
                matching: find.byType(DecoratedBox),
              )
              .first,
        ),
        const Size(88, 88),
      );
      expect(
        title(tester).style!.fontSize,
        TriageTextStyles.titleLarge.fontSize,
      );
      expect(title(tester).textAlign, TextAlign.center);
    });

    testWidgets('prominentTitle usa el título de pantalla', (tester) async {
      await tester.pumpWidget(_app(result(prominentTitle: true)));
      expect(
        title(tester).style!.fontSize,
        TriageTextStyles.screenTitle.fontSize,
      );
    });

    testWidgets('las acciones quedan abajo y responden', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(result(onPrimary: () => taps++)));
      final screenBottom = tester.getBottomLeft(find.byType(Scaffold)).dy;
      expect(
        tester.getBottomLeft(find.text('Volver a entrantes')).dy,
        greaterThan(screenBottom - 80),
      );
      await tester.tap(find.text('Ver en la sala'));
      expect(taps, 1);
    });

    testWidgets('el título se anuncia como encabezado', (tester) async {
      await tester.pumpWidget(_app(result()));
      expect(
        tester.getSemantics(find.text('Recepción confirmada')),
        isSemantics(
          label: 'Recepción confirmada',
          isHeader: true,
          namesRoute: true,
        ),
      );
    });

    testWidgets(
      'contenido largo y texto al 200 %: se desplaza, botones fijos',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(
            result(
              content: Column(
                children: [for (var i = 0; i < 30; i++) Text('Dato $i')],
              ),
            ),
            textScale: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Ver en la sala').hitTestable(), findsOneWidget);
      },
    );
  });
}
