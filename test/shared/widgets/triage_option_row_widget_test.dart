import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(
  Widget child, {
  double width = 393,
  double textScale = 1,
  TriageRoleTheme role = TriageRoleTheme.paramedic,
}) => MaterialApp(
  theme: ThemeData(extensions: [role]),
  builder: (context, navigator) => MediaQuery(
    data: MediaQueryData(
      size: Size(width, 800),
      textScaler: TextScaler.linear(textScale),
    ),
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

const _title = 'Más recientes';
const _detail = 'Los últimos en registrarse';

TriageOptionRow _check({bool selected = false, VoidCallback? onTap}) =>
    TriageOptionRow.check(
      icon: TriageIcons.clock,
      title: _title,
      detail: _detail,
      selected: selected,
      onTap: onTap ?? () {},
    );

TriageOptionRow _toggle({bool value = false, ValueChanged<bool>? onChanged}) =>
    TriageOptionRow.toggle(
      icon: TriageIcons.map,
      title: _title,
      detail: _detail,
      value: value,
      onChanged: onChanged ?? (_) {},
    );

final _track = find.byType(AnimatedContainer);

BoxDecoration _trackDecoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_track).decoration! as BoxDecoration;

Color? _titleColor(WidgetTester tester) =>
    tester.widget<Text>(find.text(_title)).style!.color;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  group('acción', () {
    testWidgets('solo ícono y textos; se anuncia como botón', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          TriageOptionRow(
            icon: TriageIcons.pencil,
            title: _title,
            detail: _detail,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.byType(TriageIcon), findsOneWidget);
      expect(_track, findsNothing);
      expect(
        tester.getSemantics(find.byType(TriageOptionRow)),
        isSemantics(label: '$_title\n$_detail', isButton: true),
      );
      await tester.tap(find.byType(TriageOptionRow));
      expect(taps, 1);
    });

    testWidgets('alto mínimo táctil', (tester) async {
      await tester.pumpWidget(_wrap(_check()));
      expect(
        tester.getSize(find.byType(TriageOptionRow)).height,
        greaterThanOrEqualTo(TriageSizes.touchTarget),
      );
    });
  });

  group('check', () {
    for (final (name, role) in [
      ('campo', TriageRoleTheme.paramedic),
      ('hospital', TriageRoleTheme.hospital),
    ]) {
      testWidgets('elegida se pinta con el color del rol $name', (
        tester,
      ) async {
        await tester.pumpWidget(_wrap(_check(selected: true), role: role));
        expect(_titleColor(tester), role.accent);
        final icons = tester.widgetList<TriageIcon>(find.byType(TriageIcon));
        expect(icons.map((icon) => icon.color), everyElement(role.accent));
        expect(icons.last.asset, TriageIcons.check);
      });
    }

    testWidgets('sin elegir no hay palomita y el texto es neutro', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_check()));
      expect(_titleColor(tester), TriageColors.textPrimary);
      expect(find.byType(TriageIcon), findsOneWidget);
    });

    testWidgets('elegirla no mueve el texto', (tester) async {
      await tester.pumpWidget(_wrap(_check()));
      final idle = tester.getSize(find.text(_title)).width;
      await tester.pumpWidget(_wrap(_check(selected: true)));
      expect(tester.getSize(find.text(_title)).width, idle);
    });

    testWidgets('el lector anuncia que está elegida', (tester) async {
      await tester.pumpWidget(_wrap(_check(selected: true)));
      expect(
        tester.getSemantics(find.byType(TriageOptionRow)),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
    });
  });

  group('interruptor', () {
    testWidgets('el círculo cambia de lado y el fondo de color', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_toggle()));
      final thumb = find.descendant(
        of: _track,
        matching: find.byType(SizedBox),
      );
      expect(tester.getCenter(thumb).dx, lessThan(tester.getCenter(_track).dx));
      expect(_trackDecoration(tester).color, TriageColors.textTertiary);

      await tester.pumpWidget(_wrap(_toggle(value: true)));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(thumb).dx,
        greaterThan(tester.getCenter(_track).dx),
      );
      expect(_trackDecoration(tester).color, TriageRoleTheme.paramedic.accent);
    });

    testWidgets('toda la fila cambia el valor', (tester) async {
      bool? received;
      await tester.pumpWidget(
        _wrap(_toggle(value: true, onChanged: (value) => received = value)),
      );
      await tester.tap(find.text(_title));
      expect(received, isFalse);
    });

    testWidgets('el lector lo anuncia como interruptor', (tester) async {
      await tester.pumpWidget(_wrap(_toggle(value: true)));
      expect(
        tester.getSemantics(find.byType(TriageOptionRow)),
        isSemantics(hasToggledState: true, isToggled: true, hasTapAction: true),
      );
    });

    testWidgets('sin onChanged queda desactivada y atenuada', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TriageOptionRow.toggle(
            icon: TriageIcons.map,
            title: _title,
            detail: _detail,
            value: false,
            onChanged: null,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TriageOptionRow)),
        isSemantics(
          hasToggledState: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity,
        TriageOpacity.disabled,
      );
    });

    testWidgets('se reduce en pantallas estrechas', (tester) async {
      await tester.pumpWidget(_wrap(_toggle(), width: 320));
      expect(tester.getSize(_track).width, closeTo(46 * 0.82, 0.1));
    });

    test('apagado y círculo con contraste ≥ 3', () {
      expect(
        _contrast(TriageColors.textTertiary, TriageColors.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(TriageColors.surface, TriageRoleTheme.paramedic.accent),
        greaterThanOrEqualTo(3),
      );
    });
  });

  testWidgets('texto al 200 % en 280: crece sin desbordarse', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SingleChildScrollView(child: Column(children: [_toggle(), _check()])),
        width: 280,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
