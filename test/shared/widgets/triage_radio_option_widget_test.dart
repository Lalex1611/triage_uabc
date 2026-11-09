import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(
  Widget child, {
  double width = 393,
  double textScale = 1,
  TriageRoleTheme role = TriageRoleTheme.hospital,
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

TriageRadioOption _option({
  bool selected = false,
  VoidCallback? onTap,
  TriageTone? tone,
  String title = 'Sin camas disponibles',
}) => TriageRadioOption(
  title: title,
  detail: 'Urgencias al límite de capacidad',
  selected: selected,
  tone: tone,
  onTap: onTap ?? () {},
);

List<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(TriageRadioOption),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => box.decoration as BoxDecoration)
    .toList();

Finder get _indicator => find
    .descendant(
      of: find.byType(TriageRadioOption),
      matching: find.byType(DecoratedBox),
    )
    .last;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('sin elegir: tarjeta blanca y círculo vacío', (tester) async {
    await tester.pumpWidget(_wrap(_option()));
    final [card, circle] = _decorations(tester);
    expect(card.color, TriageColors.surface);
    expect((card.border! as Border).top.color, TriageColors.borderMedium);
    expect(card.borderRadius, BorderRadius.circular(TriageRadii.xl));
    expect((circle.border! as Border).top.color, TriageColors.textTertiary);
    expect(find.byType(TriageIcon), findsNothing);
  });

  for (final (name, role) in [
    ('campo', TriageRoleTheme.paramedic),
    ('hospital', TriageRoleTheme.hospital),
  ]) {
    testWidgets('elegida toma el color del rol $name', (tester) async {
      await tester.pumpWidget(_wrap(_option(selected: true), role: role));
      final [card, circle] = _decorations(tester);
      expect(card.color, role.soft);
      expect((card.border! as Border).top.color, role.accent);
      expect(circle.color, role.accent);
      expect(
        tester.widget<TriageIcon>(find.byType(TriageIcon)).asset,
        TriageIcons.check,
      );
    });
  }

  testWidgets('un tono sustituye al color del rol', (tester) async {
    await tester.pumpWidget(
      _wrap(_option(selected: true, tone: TriageTone.success)),
    );
    final [card, circle] = _decorations(tester);
    expect(card.color, TriageTone.success.background);
    expect((card.border! as Border).top.color, TriageTone.success.color);
    expect(circle.color, TriageTone.success.color);
  });

  testWidgets('elegirla no cambia la altura', (tester) async {
    await tester.pumpWidget(_wrap(_option()));
    final idle = tester.getSize(find.byType(TriageRadioOption));
    await tester.pumpWidget(_wrap(_option(selected: true)));
    expect(tester.getSize(find.byType(TriageRadioOption)), idle);
  });

  testWidgets('toda la tarjeta responde y mide al menos 48', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_option(onTap: () => taps++)));
    final card = find.byType(TriageRadioOption);
    expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
    await tester.tapAt(tester.getTopRight(card) + const Offset(-20, 8));
    expect(taps, 1);
  });

  testWidgets('el lector la anuncia como opción excluyente', (tester) async {
    await tester.pumpWidget(_wrap(_option(selected: true)));
    expect(
      tester.getSemantics(find.byType(TriageRadioOption)),
      isSemantics(
        label: 'Sin camas disponibles\nUrgencias al límite de capacidad',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('el círculo se reduce en pantallas estrechas', (tester) async {
    await tester.pumpWidget(_wrap(_option(), width: 320));
    expect(tester.getSize(_indicator).width, closeTo(22 * 0.82, 0.1));
  });

  testWidgets('texto al 200 % en 280: crece sin desbordarse', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _option(title: 'Equipo o quirófano ocupado en este momento'),
        width: 280,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TriageRadioOption)).height,
      greaterThan(100),
    );
  });

  test('el círculo y la palomita tienen contraste ≥ 3', () {
    expect(
      _contrast(TriageColors.textTertiary, TriageColors.surface),
      greaterThanOrEqualTo(3),
    );
    for (final accent in [
      TriageRoleTheme.paramedic.accent,
      TriageRoleTheme.hospital.accent,
      TriageTone.success.color,
    ]) {
      expect(
        _contrast(TriageColors.textInverse, accent),
        greaterThanOrEqualTo(3),
      );
    }
  });
}
