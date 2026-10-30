import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child) => MaterialApp(home: Center(child: child));

Material _pill(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(TriageChip), matching: find.byType(Material))
      .first,
);

void main() {
  testWidgets('seleccionado: fondo oscuro y texto blanco', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageChip(label: 'Todos', selected: true, onTap: () {})),
    );
    expect(_pill(tester).color, TriageColors.inverse);
    expect(
      tester.widget<Text>(find.text('Todos')).style!.color,
      TriageColors.textInverse,
    );
  });

  testWidgets('no seleccionado: fondo blanco con borde y texto secundario', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageChip(label: 'Rojo', selected: false, onTap: () {})),
    );
    final pill = _pill(tester);
    expect(pill.color, TriageColors.surface);
    expect((pill.shape as StadiumBorder).side.color, TriageColors.borderMedium);
    expect(
      tester.widget<Text>(find.text('Rojo')).style!.color,
      TriageColors.textSecondary,
    );
  });

  testWidgets('píldora de 38 y zona táctil de 44', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageChip(label: 'Verde', selected: false, onTap: () {})),
    );
    expect(tester.getSize(find.byType(TriageChip)).height, 44);
    expect(tester.getSize(find.byType(InkWell)).height, 38);
  });

  testWidgets('responde al toque en la píldora y en el margen invisible', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(TriageChip(label: 'Negro', selected: false, onTap: () => taps++)),
    );
    await tester.tap(find.text('Negro'));
    // 1 px dentro del borde superior de la zona de 44, fuera de la píldora
    final topLeft = tester.getTopLeft(find.byType(TriageChip));
    await tester.tapAt(topLeft + const Offset(20, 1));
    expect(taps, 2);
  });

  testWidgets('expone el estado seleccionado al lector de pantalla', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageChip(label: 'Todos', selected: true, onTap: () {})),
    );
    expect(
      tester.getSemantics(find.text('Todos')),
      isSemantics(
        label: 'Todos',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });
}
