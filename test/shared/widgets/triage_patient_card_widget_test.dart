import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

/// Pantalla de 320 de ancho (teléfono pequeño)
void _narrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(960, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('muestra nombre, detalle, insignia y barra del nivel', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriagePatientCard(
          name: 'Bruce Cervantes',
          detail: 'PAC-2031 · 14:34 · hemorragia',
          level: TriageLevel.red,
          badge: TriageStatusBadge.patient(PatientLifecycleStatus.transferring),
        ),
      ),
    );
    expect(find.text('Bruce Cervantes'), findsOneWidget);
    expect(find.text('PAC-2031 · 14:34 · hemorragia'), findsOneWidget);
    expect(find.text('TRASLADANDO'), findsOneWidget);
    final bar = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(TriagePatientCard),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((bar.decoration! as BoxDecoration).color, TriageColors.triageRed);
  });

  testWidgets('toda la tarjeta responde y se anuncia como un botón', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        TriagePatientCard(
          name: 'Alan Torres',
          detail: 'PAC-2034',
          level: TriageLevel.green,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('PAC-2034'));
    expect(taps, 1);
    final node = tester.getSemantics(find.text('Alan Torres'));
    expect(
      node,
      isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
    );
    expect(node.label, contains('Triage Verde'));
    expect(node.label, contains('Alan Torres'));
  });

  testWidgets('sala: cuadro con el número del triage hospitalario', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TriagePatientCard.room(
          name: 'Lourdes Carrillo',
          detail: 'Hace 22 min',
          level: TriageLevel.orange,
          badge: TriageStatusBadge.patient(PatientLifecycleStatus.waiting),
        ),
      ),
    );
    expect(find.text('NIVEL'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // La insignia va en la fila del nombre
    expect(
      tester.getCenter(find.text('EN ESPERA')).dy,
      closeTo(tester.getCenter(find.text('Lourdes Carrillo')).dy, 2),
    );
    expect(
      tester.getSemantics(find.text('Lourdes Carrillo')).label,
      contains('Nivel 2, Naranja'),
    );
  });

  test('sala no admite negro (no es nivel hospitalario)', () {
    expect(
      () => TriagePatientCard.room(
        name: 'x',
        detail: 'x',
        level: TriageLevel.values.last,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('con texto al 200 % en pantalla de 320 no se desborda', (
    tester,
  ) async {
    _narrowScreen(tester);
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            TriagePatientCard(
              name: 'Paciente sin identificar',
              detail: 'PAC-2032 · 14:36 · inconsciente',
              level: TriageLevel.red,
              badge: TriageStatusBadge.patient(PatientLifecycleStatus.waiting),
              onTap: () {},
            ),
            TriagePatientCard.room(
              name: 'Ramiro Hernández',
              detail: 'Hace 35 min · del incidente INC-731',
              level: TriageLevel.yellow,
              badge: TriageStatusBadge.patient(PatientLifecycleStatus.waiting),
              onTap: () {},
            ),
          ],
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
