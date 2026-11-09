import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(
  Widget child, {
  Size size = const Size(393, 800),
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, navigator) => MediaQuery(
    data: MediaQueryData(
      size: size,
      padding: padding,
      textScaler: TextScaler.linear(textScale),
    ),
    child: navigator!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(width: size.width, child: child),
    ),
  ),
);

TriageButton _button(String label, {VoidCallback? onPressed}) =>
    TriageButton(label: label, onPressed: onPressed ?? () {});

final _leading = TriageIconButton(
  icon: TriageIcons.qr,
  tooltip: 'Código de consulta',
  size: TriageIconButtonSize.large,
  onPressed: () {},
);

void main() {
  void setScreen(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('superficie blanca con la sombra de barra', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageActionBar(primary: _button('Registrar'))),
    );
    final bar =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(TriageActionBar),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(bar.color, TriageColors.surface);
    expect(bar.boxShadow, TriageShadows.bar);
  });

  testWidgets('solo con primary ocupa todo el ancho entre márgenes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageActionBar(primary: _button('Registrar paciente'))),
    );
    expect(
      tester.getSize(find.byType(TriageButton)).width,
      393 - 2 * TriageSpacing.xxl,
    );
  });

  testWidgets('con secondary se reparten 2:3', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageActionBar(
          secondary: _button('Cancelar'),
          primary: _button('Guardar paciente'),
        ),
      ),
    );
    final secondary = tester.getSize(find.byType(TriageButton).first).width;
    final primary = tester.getSize(find.byType(TriageButton).last).width;
    expect(primary / secondary, closeTo(1.5, 0.01));
    expect(
      tester.getCenter(find.text('Cancelar')).dx,
      lessThan(tester.getCenter(find.text('Guardar paciente')).dx),
    );
  });

  testWidgets('leading va a la izquierda y el botón toma el resto', (
    tester,
  ) async {
    setScreen(tester, const Size(393, 800));
    await tester.pumpWidget(
      _wrap(TriageActionBar(leading: _leading, primary: _button('Reasignar'))),
    );
    expect(
      tester.getTopLeft(find.byType(TriageIconButton)).dx,
      TriageSpacing.xxl,
    );
    expect(
      tester.getTopRight(find.byType(TriageButton)).dx,
      393 - TriageSpacing.xxl,
    );
    expect(
      tester.getTopLeft(find.byType(TriageButton)).dx,
      TriageSpacing.xxl + TriageSizes.controlLarge + TriageSpacing.sm,
    );
  });

  testWidgets('margen lateral menor en pantallas estrechas', (tester) async {
    setScreen(tester, const Size(320, 800));
    await tester.pumpWidget(
      _wrap(
        TriageActionBar(primary: _button('Registrar')),
        size: const Size(320, 800),
      ),
    );
    expect(tester.getTopLeft(find.byType(TriageButton)).dx, TriageSpacing.md);
  });

  testWidgets('respeta la zona segura inferior', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageActionBar(primary: _button('Registrar')),
        padding: const EdgeInsets.only(bottom: 34),
      ),
    );
    final bar = tester.getBottomLeft(find.byType(TriageActionBar)).dy;
    expect(tester.getBottomLeft(find.byType(TriageButton)).dy, bar - 34);
  });

  testWidgets('los botones responden al toque', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        TriageActionBar(
          secondary: _button('Cancelar', onPressed: () => taps += 10),
          primary: _button('Guardar', onPressed: () => taps++),
        ),
      ),
    );
    await tester.tap(find.text('Cancelar'));
    await tester.tap(find.text('Guardar'));
    expect(taps, 11);
  });

  testWidgets('texto al 200 % en 320: mismo alto y sin desbordes', (
    tester,
  ) async {
    setScreen(tester, const Size(320, 800));
    await tester.pumpWidget(
      _wrap(
        TriageActionBar(
          leading: _leading,
          secondary: _button('Cancelar registro'),
          primary: _button('Guardar paciente registrado'),
        ),
        size: const Size(320, 800),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TriageButton).first).height,
      tester.getSize(find.byType(TriageButton).last).height,
    );
  });
}
