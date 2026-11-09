import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Como en el mapa: dentro de una celda de tamaño fijo
Widget _wrap(Widget child, {double textScale = 1, double width = 88}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: TriageSizes.touchTarget,
              child: child,
            ),
          ),
        ),
      ),
    );

final _pill = find.descendant(
  of: find.byType(TriageIncidentMarker),
  matching: find.byType(Container),
);

BoxDecoration _pillDecoration(WidgetTester tester) =>
    tester.widget<Container>(_pill.first).decoration! as BoxDecoration;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('normal: píldora blanca de 42 con borde rojo', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageIncidentMarker(patientCount: 8, onTap: () {})),
    );
    final decoration = _pillDecoration(tester);
    expect(decoration.color, TriageColors.surface);
    expect(
      (decoration.border! as Border).top.color,
      TriageColors.paramedicAccent,
    );
    expect(decoration.boxShadow, TriageShadows.floating);
    expect(tester.getSize(_pill.first).height, 42);
    expect(
      tester.widget<Text>(find.text('8')).style!.color,
      TriageColors.textPrimary,
    );
  });

  testWidgets('seleccionado: píldora roja de 48 con texto blanco', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageIncidentMarker(patientCount: 8, selected: true, onTap: () {}),
      ),
    );
    final decoration = _pillDecoration(tester);
    expect(decoration.color, TriageColors.paramedicAccent);
    expect(decoration.border, isNull);
    expect(tester.getSize(_pill.first).height, 48);
    expect(
      tester.widget<Text>(find.text('8')).style!.color,
      TriageColors.textInverse,
    );
  });

  testWidgets('usa el ícono de alerta del sistema de diseño', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageIncidentMarker(patientCount: 1, onTap: () {})),
    );
    expect(
      tester.widget<TriageIcon>(find.byType(TriageIcon)).asset,
      TriageIcons.alert,
    );
  });

  testWidgets('responde al toque en toda la celda', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(TriageIncidentMarker(patientCount: 3, onTap: () => taps++)),
    );
    final cell = find.byType(TriageIncidentMarker);
    await tester.tapAt(tester.getTopLeft(cell) + const Offset(1, 1));
    expect(taps, 1);
  });

  testWidgets('se anuncia como botón, en singular o plural', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageIncidentMarker(patientCount: 1, selected: true, onTap: () {}),
      ),
    );
    expect(
      tester.getSemantics(find.byType(TriageIncidentMarker)),
      isSemantics(
        label: 'Incidente con 1 paciente\n1',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(
      _wrap(TriageIncidentMarker(patientCount: 3, onTap: () {})),
    );
    expect(
      tester.getSemantics(find.byType(TriageIncidentMarker)),
      isSemantics(label: 'Incidente con 3 pacientes\n3', isButton: true),
    );
  });

  test('contraste del conteo y del ícono', () {
    expect(
      _contrast(TriageColors.textPrimary, TriageColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(TriageColors.textInverse, TriageColors.paramedicAccent),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('conteo largo y texto al 200 % se reducen sin desbordarse', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriageIncidentMarker(patientCount: 128, selected: true, onTap: () {}),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
