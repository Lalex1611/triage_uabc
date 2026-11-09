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
      _wrap(
        TriageTabs(labels: _labels, selectedIndex: 0, onChanged: (_) {}),
        width: 600,
      ),
    );
    final cells = find.descendant(
      of: find.byType(TriageTabs),
      matching: find.byType(GestureDetector),
    );
    final widths = cells.evaluate().map((e) => e.size!.width).toSet();
    expect(widths.length, 1, reason: 'todas del mismo ancho');
    expect(tester.getSize(cells.first).height, 46);
  });

  group('cuando no caben a partes iguales', () {
    Widget narrow({int selectedIndex = 0, ValueChanged<int>? onChanged}) =>
        _wrap(
          TriageTabs(
            labels: _labels,
            selectedIndex: selectedIndex,
            onChanged: onChanged ?? (_) {},
          ),
          width: 220,
        );

    final scrollable = find.descendant(
      of: find.byType(TriageTabs),
      matching: find.byType(Scrollable),
    );

    testWidgets('se desplazan sin desbordar y sin reducir el texto', (
      tester,
    ) async {
      await tester.pumpWidget(narrow());
      expect(tester.takeException(), isNull);
      expect(scrollable, findsOneWidget);
      expect(find.byType(FittedBox), findsNothing);
      expect(
        tester.widget<Text>(find.text('Pacientes')).style!.fontSize,
        TriageTextStyles.labelMedium.fontSize,
      );
    });

    testWidgets('al desplazarse se puede tocar la última pestaña', (
      tester,
    ) async {
      int? changed;
      await tester.pumpWidget(narrow(onChanged: (i) => changed = i));
      await tester.drag(scrollable, const Offset(-1000, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resumen'));
      expect(changed, 3);
    });

    testWidgets('mantiene a la vista la pestaña seleccionada', (tester) async {
      await tester.pumpWidget(narrow(selectedIndex: 3));
      await tester.pump();
      expect(find.text('Resumen').hitTestable(), findsOneWidget);

      await tester.pumpWidget(narrow());
      await tester.pumpAndSettle();
      expect(find.text('Pacientes').hitTestable(), findsOneWidget);
    });
  });

  testWidgets('si no caben iguales, se reparten según su texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageTabs(labels: _labels, selectedIndex: 0, onChanged: (_) {}),
        width: 500,
      ),
    );
    expect(tester.takeException(), isNull);
    Size cellOf(String label) => tester.getSize(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(cellOf('Pacientes').width, greaterThan(cellOf('Mapa').width));
    expect(
      find.descendant(
        of: find.byType(TriageTabs),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });

  testWidgets('con espacio suficiente no hay desplazamiento', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageTabs(labels: _labels, selectedIndex: 0, onChanged: (_) {}),
        width: 600,
      ),
    );
    expect(
      find.descendant(
        of: find.byType(TriageTabs),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
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
