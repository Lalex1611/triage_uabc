import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {TriageRoleTheme? role, double textScale = 1}) =>
    MaterialApp(
      theme: ThemeData(extensions: [?role]),
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

TriageIncidentCard _card({
  bool selected = false,
  int patients = 8,
  VoidCallback? onTap,
}) => TriageIncidentCard(
  folio: 'INC-729',
  timeAgo: 'hace 18 min',
  title: 'Accidente vehicular',
  location: 'Blvd. Díaz Ordaz y Ferrocarril · a 1.4 km',
  counts: const {TriageLevel.red: 3, TriageLevel.yellow: 2},
  patientCount: patients,
  selected: selected,
  onTap: onTap,
);

Border _border(WidgetTester tester) =>
    (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(TriageIncidentCard),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .border!
        as Border;

void main() {
  testWidgets('muestra folio, tiempo, título, ubicación, conteo y total', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card()));
    for (final text in [
      'INC-729',
      'hace 18 min',
      'Accidente vehicular',
      'Blvd. Díaz Ordaz y Ferrocarril · a 1.4 km',
      '8 pacientes',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.byType(TriageLevelCount), findsOneWidget);
  });

  testWidgets('"1 paciente" en singular', (tester) async {
    await tester.pumpWidget(_wrap(_card(patients: 1)));
    expect(find.text('1 paciente'), findsOneWidget);
  });

  testWidgets('seleccionada: borde del color del rol y estado anunciado', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card()));
    expect(_border(tester).top.color, TriageColors.borderSubtle);

    await tester.pumpWidget(
      _wrap(_card(selected: true), role: TriageRoleTheme.hospital),
    );
    await tester.pumpAndSettle();
    expect(_border(tester).top.color, TriageColors.hospitalAccent);
    expect(
      tester.getSemantics(find.text('Accidente vehicular')),
      isSemantics(isButton: true, isSelected: true),
    );
  });

  testWidgets('toda la tarjeta responde al toque', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_card(onTap: () => taps++)));
    await tester.tap(find.text('8 pacientes'));
    expect(taps, 1);
  });

  testWidgets('con texto al 200 % en pantalla de 320 no se desborda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(_card(), textScale: 2));
    expect(tester.takeException(), isNull);
  });
}
