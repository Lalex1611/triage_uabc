import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

const _labels = ['Pacientes', 'Mapa', 'Detalles', 'Resumen'];

Widget _wrap(Widget child, {double width = 360}) => MaterialApp(
  home: Center(
    child: SizedBox(width: width, child: child),
  ),
);

void main() {
  testWidgets('cambia de pestaña al tocar y avisa el índice', (tester) async {
    int? changed;
    await tester.pumpWidget(
      _wrap(
        TriageTabs(
          labels: _labels,
          selectedIndex: 0,
          onChanged: (i) => changed = i,
        ),
      ),
    );
    await tester.tap(find.text('Detalles'));
    expect(changed, 2);
  });

  testWidgets('pestaña activa con texto primario, el resto secundario', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageTabs(labels: _labels, selectedIndex: 1, onChanged: (_) {})),
    );
    Color? colorOf(String l) => tester.widget<Text>(find.text(l)).style!.color;
    expect(colorOf('Mapa'), TriageColors.textPrimary);
    expect(colorOf('Pacientes'), TriageColors.textSecondary);
  });

  testWidgets('las pestañas se reparten el ancho y la zona táctil mide 46', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageTabs(labels: _labels, selectedIndex: 0, onChanged: (_) {})),
    );
    final cells = find.descendant(
      of: find.byType(TriageTabs),
      matching: find.byType(GestureDetector),
    );
    final widths = cells.evaluate().map((e) => e.size!.width).toSet();
    expect(widths.length, 1, reason: 'todas del mismo ancho');
    expect(tester.getSize(cells.first).height, 46);
  });

  testWidgets('en pantalla angosta reduce el texto sin desbordar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageTabs(labels: _labels, selectedIndex: 0, onChanged: (_) {}),
        width: 220,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Pacientes'), findsOneWidget);
  });

  testWidgets('el lector anuncia cada pestaña como botón y la activa', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(TriageTabs(labels: _labels, selectedIndex: 0, onChanged: (_) {})),
    );
    expect(
      tester.getSemantics(find.text('Pacientes')),
      isSemantics(
        label: 'Pacientes',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
