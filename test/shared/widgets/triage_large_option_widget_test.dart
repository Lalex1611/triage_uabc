import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(
  Widget child, {
  TriageRoleTheme role = TriageRoleTheme.paramedic,
  double width = 342,
  double textScale = 1,
}) => MaterialApp(
  theme: ThemeData(extensions: [role]),
  home: MediaQuery(
    data: MediaQueryData(
      size: Size(width, 800),
      textScaler: TextScaler.linear(textScale),
    ),
    child: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

TriageLargeOption _option({
  bool neutral = false,
  bool highlighted = false,
  VoidCallback? onTap,
}) => TriageLargeOption(
  icon: TriageIcons.clipboard,
  title: 'START guiado',
  detail: 'Responde 4 o 5 preguntas cortas y el sistema propone el color.',
  onTap: onTap ?? () {},
  neutral: neutral,
  highlighted: highlighted,
);

BoxDecoration _card(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(TriageLargeOption),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

BoxDecoration _symbol(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(TriageLargeOption),
                    matching: find.byType(DecoratedBox),
                  )
                  .last,
            )
            .decoration
        as BoxDecoration;

ColorFilter? _iconFilter(WidgetTester tester) =>
    tester.widget<SvgPicture>(find.byType(SvgPicture).first).colorFilter;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  for (final (name, role) in [
    ('campo', TriageRoleTheme.paramedic),
    ('hospital', TriageRoleTheme.hospital),
  ]) {
    testWidgets('el ícono toma el color del rol $name', (tester) async {
      await tester.pumpWidget(_wrap(_option(), role: role));
      expect(_symbol(tester).color, role.soft);
      expect(
        _iconFilter(tester),
        ColorFilter.mode(role.accent, BlendMode.srcIn),
      );
    });
  }

  for (final (name, role) in [
    ('campo', TriageRoleTheme.paramedic),
    ('hospital', TriageRoleTheme.hospital),
  ]) {
    testWidgets('tenue: fondo, borde y símbolo del rol $name', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TriageLargeOption(
            icon: TriageIcons.alert,
            title: 'Emergencias',
            detail: 'Registro directo',
            tinted: true,
            onTap: () {},
          ),
          role: role,
        ),
      );
      expect(_card(tester).color, role.soft);
      expect((_card(tester).border! as Border).top.color, role.accent);
      expect(_symbol(tester).color, role.accent);
      expect(
        _iconFilter(tester),
        const ColorFilter.mode(TriageColors.textInverse, BlendMode.srcIn),
      );
      expect(
        _contrast(TriageColors.textInverse, role.accent),
        greaterThanOrEqualTo(3),
      );
    });
  }

  testWidgets('neutral: ícono oscuro sobre gris', (tester) async {
    await tester.pumpWidget(_wrap(_option(neutral: true)));
    expect(_symbol(tester).color, TriageColors.sunken);
    expect(
      _iconFilter(tester),
      const ColorFilter.mode(TriageColors.textPrimary, BlendMode.srcIn),
    );
  });

  testWidgets('borde normal y, resaltada, del color del rol', (tester) async {
    await tester.pumpWidget(_wrap(_option()));
    expect(
      (_card(tester).border! as Border).top.color,
      TriageColors.borderMedium,
    );

    await tester.pumpWidget(
      _wrap(_option(highlighted: true), role: TriageRoleTheme.hospital),
    );
    await tester.pumpAndSettle(); // MaterialApp anima el cambio de tema
    final side = (_card(tester).border! as Border).top;
    expect(side.color, TriageRoleTheme.hospital.accent);
    expect(side.width, TriageSizes.strokeStrong);
  });

  testWidgets('responde al toque en toda la tarjeta', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_option(onTap: () => taps++)));
    await tester.tap(find.text('START guiado'));
    await tester.tap(find.byType(SvgPicture).last);
    expect(taps, 2);
  });

  testWidgets('el lector la anuncia como un solo botón', (tester) async {
    await tester.pumpWidget(_wrap(_option()));
    expect(
      tester.getSemantics(find.text('START guiado')),
      isSemantics(
        label:
            'START guiado\nResponde 4 o 5 preguntas cortas y el sistema propone el color.',
        isButton: true,
        hasTapAction: true,
      ),
    );
  });

  test('contraste de texto e íconos en ambos roles', () {
    const surface = TriageColors.surface;
    expect(
      _contrast(TriageColors.textSecondary, surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(TriageColors.textTertiary, surface),
      greaterThanOrEqualTo(3),
    );
    expect(
      _contrast(TriageColors.textPrimary, TriageColors.sunken),
      greaterThanOrEqualTo(3),
    );
    for (final role in [TriageRoleTheme.paramedic, TriageRoleTheme.hospital]) {
      expect(_contrast(role.accent, role.soft), greaterThanOrEqualTo(3));
    }
  });

  testWidgets('el símbolo se reduce en pantallas estrechas', (tester) async {
    Size symbolSize() => tester.getSize(
      find
          .descendant(
            of: find.byType(TriageLargeOption),
            matching: find.byType(DecoratedBox),
          )
          .last,
    );

    await tester.pumpWidget(_wrap(_option(), width: 393));
    expect(symbolSize(), const Size(50, 50));

    await tester.pumpWidget(_wrap(_option(), width: 320));
    expect(symbolSize().width, closeTo(50 * 0.82, 0.1));
  });

  testWidgets('se ajusta al contenido y crece con el texto al 200 %', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_option()));
    final normal = tester.getSize(find.byType(TriageLargeOption)).height;
    expect(normal, lessThan(300)); // No ocupa los 600 de la pantalla de prueba

    await tester.pumpWidget(_wrap(_option(), width: 288, textScale: 2));
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TriageLargeOption)).height,
      greaterThan(normal),
    );
  });
}
