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

TriageNotificationCard _card({
  bool unread = false,
  VoidCallback? onTap,
  TriageTone tone = TriageTone.danger,
}) => TriageNotificationCard(
  icon: TriageIcons.ambulance,
  tone: tone,
  title: 'Paciente rojo en camino',
  message: 'Alberto Pérez (PAC-2031) llega en 6 min desde INC-729.',
  timeAgo: 'hace 1 min',
  unread: unread,
  onTap: onTap ?? () {},
);

final _decorated = find.descendant(
  of: find.byType(TriageNotificationCard),
  matching: find.byType(DecoratedBox),
);

BoxDecoration _surface(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_decorated.first).decoration as BoxDecoration;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('sin leer: fondo blanco, sombra y punto', (tester) async {
    await tester.pumpWidget(_wrap(_card(unread: true)));
    expect(_surface(tester).color, TriageColors.surface);
    expect(_surface(tester).boxShadow, TriageShadows.card);
    expect(find.bySemanticsLabel(RegExp('Sin leer')), findsOneWidget);
  });

  testWidgets('leída: integrada con el fondo y sin punto', (tester) async {
    await tester.pumpWidget(_wrap(_card()));
    expect(_surface(tester).color, TriageColors.canvas);
    expect(_surface(tester).boxShadow, isNull);
    expect(find.bySemanticsLabel(RegExp('Sin leer')), findsNothing);
  });

  for (final tone in TriageTone.values) {
    testWidgets('tono ${tone.name}: recuadro e ícono', (tester) async {
      await tester.pumpWidget(_wrap(_card(tone: tone)));
      final symbol =
          tester.widget<DecoratedBox>(_decorated.at(1)).decoration
              as BoxDecoration;
      expect(symbol.color, tone.background);
      expect(
        tester.widget<TriageIcon>(find.byType(TriageIcon)).color,
        tone.color,
      );
      expect(_contrast(tone.color, tone.background), greaterThanOrEqualTo(3));
    });
  }

  testWidgets('el punto toma el color del rol', (tester) async {
    await tester.pumpWidget(
      _wrap(_card(unread: true), role: TriageRoleTheme.paramedic),
    );
    final dot =
        tester.widget<DecoratedBox>(_decorated.last).decoration
            as BoxDecoration;
    expect(dot.color, TriageRoleTheme.paramedic.accent);
  });

  testWidgets('toda la tarjeta responde y se lee entera', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_card(unread: true, onTap: () => taps++)));
    final card = find.byType(TriageNotificationCard);
    await tester.tapAt(tester.getBottomRight(card) - const Offset(8, 8));
    expect(taps, 1);
    final label = tester.getSemantics(card).getSemanticsData().label;
    expect(label, contains('Paciente rojo en camino'));
    expect(label, contains('Sin leer'));
    expect(label, contains('hace 1 min'));
  });

  test('el tiempo y el mensaje llegan a 4.5:1 en ambos fondos', () {
    for (final background in [TriageColors.surface, TriageColors.canvas]) {
      expect(
        _contrast(TriageColors.textSecondary, background),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('el recuadro se reduce en pantallas estrechas', (tester) async {
    await tester.pumpWidget(_wrap(_card(), width: 320));
    expect(tester.getSize(_decorated.at(1)).width, closeTo(42 * 0.82, 0.1));
  });

  testWidgets('texto al 200 % en 280: crece sin desbordarse', (tester) async {
    await tester.pumpWidget(
      _wrap(_card(unread: true), width: 280, textScale: 2),
    );
    expect(tester.takeException(), isNull);
  });
}
