import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double width = 393}) => MaterialApp(
  builder: (context, navigator) => MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: navigator!,
  ),
  home: Scaffold(body: Center(child: child)),
);

TriageIconButton _button({
  TriageIconButtonVariant variant = TriageIconButtonVariant.sunken,
  TriageIconButtonSize size = TriageIconButtonSize.compact,
  VoidCallback? onPressed,
  bool enabled = true,
}) => TriageIconButton(
  icon: TriageIcons.sort,
  tooltip: 'Ordenar',
  variant: variant,
  size: size,
  onPressed: enabled ? (onPressed ?? () {}) : null,
);

final _visual = find.byWidgetPredicate(
  (w) => w is Container && w.decoration is BoxDecoration,
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<Container>(_visual).decoration! as BoxDecoration;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('compacto: círculo gris de 38 con zona táctil de 48', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_button()));
    expect(tester.getSize(find.byTooltip('Ordenar')), const Size(48, 48));
    expect(tester.getSize(_visual), const Size(38, 38));
    final decoration = _decoration(tester);
    expect(decoration.color, TriageColors.sunken);
    expect(decoration.borderRadius, BorderRadius.circular(TriageRadii.full));
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('sobre mapas: blanco con sombra', (tester) async {
    await tester.pumpWidget(
      _wrap(_button(variant: TriageIconButtonVariant.surface)),
    );
    final decoration = _decoration(tester);
    expect(decoration.color, TriageColors.surface);
    expect(decoration.boxShadow, TriageShadows.base);
  });

  testWidgets('sin fondo: no pinta círculo y mantiene la zona táctil', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_button(variant: TriageIconButtonVariant.plain)),
    );
    expect(_visual, findsNothing);
    expect(tester.getSize(find.byTooltip('Ordenar')), const Size(48, 48));
  });

  testWidgets('pequeño: zona táctil de 44 e ícono de 18', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _button(
          variant: TriageIconButtonVariant.plain,
          size: TriageIconButtonSize.small,
        ),
      ),
    );
    expect(
      tester.getSize(find.byTooltip('Ordenar')),
      const Size.square(TriageSizes.touchTargetCompact),
    );
    expect(
      tester.widget<TriageIcon>(find.byType(TriageIcon)).size,
      TriageSizes.iconSmall,
    );
  });

  testWidgets('sobre la banda: fondo translúcido, color y círculo propios', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageIconButton(
          icon: TriageIcons.user,
          tooltip: 'Perfil',
          variant: TriageIconButtonVariant.onAccent,
          color: TriageColors.textInverse,
          diameter: 44,
          iconSize: TriageSizes.iconLarge,
          onPressed: () {},
        ),
        width: 320,
      ),
    );
    expect(_decoration(tester).color, TriageColors.overlayOnAccent);
    expect(tester.getSize(_visual), const Size(44, 44));
    final icon = tester.widget<TriageIcon>(find.byType(TriageIcon));
    expect(icon.color, TriageColors.textInverse);
    expect(icon.size, TriageSizes.iconLarge);
  });

  testWidgets('el punto de avisos solo aparece con showDot', (tester) async {
    const dot = ValueKey('triage-header-dot');
    await tester.pumpWidget(_wrap(_button()));
    expect(find.byKey(dot), findsNothing);

    await tester.pumpWidget(
      _wrap(
        TriageIconButton(
          icon: TriageIcons.bell,
          tooltip: 'Avisos',
          showDot: true,
          onPressed: () {},
        ),
      ),
    );
    expect(find.byKey(dot), findsOneWidget);
  });

  testWidgets('grande: recuadro a la altura de un botón grande', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_button(size: TriageIconButtonSize.large)));
    expect(
      tester.getSize(find.byTooltip('Ordenar')),
      const Size.square(TriageSizes.controlLarge),
    );
    expect(
      _decoration(tester).borderRadius,
      BorderRadius.circular(TriageRadii.lg),
    );
  });

  testWidgets(
    'en pantallas estrechas el círculo se reduce, la zona táctil no',
    (tester) async {
      await tester.pumpWidget(_wrap(_button(), width: 320));
      expect(tester.getSize(_visual).width, closeTo(38 * 0.82, 0.1));
      expect(tester.getSize(find.byTooltip('Ordenar')), const Size(48, 48));
    },
  );

  testWidgets('el grande no baja de la zona táctil en pantallas estrechas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_button(size: TriageIconButtonSize.large), width: 280),
    );
    expect(
      tester.getSize(find.byTooltip('Ordenar')).width,
      greaterThanOrEqualTo(TriageSizes.touchTarget),
    );
  });

  testWidgets('responde al toque en toda la zona táctil', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_button(onPressed: () => taps++)));
    final target = find.byTooltip('Ordenar');
    await tester.tapAt(tester.getTopLeft(target) + const Offset(24, 2));
    expect(taps, 1);
  });

  testWidgets('el lector anuncia el tooltip como botón', (tester) async {
    await tester.pumpWidget(_wrap(_button()));
    expect(
      tester.getSemantics(find.byTooltip('Ordenar')),
      isSemantics(
        tooltip: 'Ordenar',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('sin onPressed se atenúa y no responde', (tester) async {
    await tester.pumpWidget(_wrap(_button(enabled: false)));
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(TriageIconButton),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      TriageOpacity.disabled,
    );
    expect(
      tester.getSemantics(find.byTooltip('Ordenar')),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
  });

  test('ícono con contraste ≥ 3 sobre sus fondos', () {
    for (final background in [TriageColors.sunken, TriageColors.surface]) {
      expect(
        _contrast(TriageColors.textPrimary, background),
        greaterThanOrEqualTo(3),
      );
    }
  });
}
