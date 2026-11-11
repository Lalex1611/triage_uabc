import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_flow.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

import 'fake_intake_repository.dart';

class _Harness {
  _Harness({FakeIntakeRepository? repo})
    : repo = repo ?? FakeIntakeRepository();

  final FakeIntakeRepository repo;
  int changes = 0;
  final legacy = <String>[];

  Widget app({double textScale = 1}) => MaterialApp(
    builder: (context, navigator) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: navigator!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => startPatientIntake(
            context,
            incidentId: 'a1b2c3d4',
            subtitle: 'INC-A1B2C3 · Accidente vehicular',
            onPatientsChanged: () => changes++,
            openGuidedStart: () async => legacy.add('start'),
            openExtendedRegistration: () async => legacy.add('extendido'),
            session: PatientIntakeSession(
              incidentId: 'a1b2c3d4',
              repository: repo,
              currentPosition: () async => (lat: 1.0, lng: 2.0),
              placeLabel: (_, _) async => 'Blvd. 2000',
            ),
          ),
          child: const Text('Registrar'),
        ),
      ),
    ),
  );
}

@visibleForTesting
Widget harnessApp() => _Harness().app();

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Registrar'));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String option) async {
  await tester.ensureVisible(find.text(option));
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

Future<void> _pickAndSave(WidgetTester tester, String levelTitle) async {
  await tester.ensureVisible(find.text(levelTitle));
  await tester.tap(find.text(levelTitle));
  await tester.pump();
  await tester.ensureVisible(find.text('Guardar paciente'));
  await tester.tap(find.text('Guardar paciente'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('B11 ofrece los cuatro métodos', (tester) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    expect(find.text('¿Cómo lo vas a clasificar?'), findsOneWidget);
    for (final option in [
      'START guiado',
      'Asignar color directo',
      'Emergencias',
      'Registro extendido',
    ]) {
      expect(find.text(option), findsOneWidget);
    }
  });

  for (final (option, expected) in const [
    ('START guiado', 'start'),
    ('Registro extendido', 'extendido'),
  ]) {
    testWidgets('$option cierra B11 y abre su pantalla', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.app());
      await _open(tester);
      await _choose(tester, option);
      expect(h.legacy, [expected]);
      expect(find.byType(TriageSheet), findsNothing);
    });
  }

  testWidgets('asignar color: un paciente, diálogo y una sola hoja', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Asignar color directo');
    expect(find.byType(TriageSheet), findsOneWidget);
    expect(find.text('Paciente 6 · INC-A1B2C3'), findsOneWidget);

    await _pickAndSave(tester, 'Urgente');
    expect(h.repo.registered.single['triage'], 'amarillo');
    expect(h.changes, 1);
    expect(find.text('PAC-ABCDEF quedó registrado'), findsOneWidget);
    expect(
      find.text('Van 6 pacientes clasificados en este incidente.'),
      findsOneWidget,
    );
    expect(find.text('ABC123'), findsNothing);

    await tester.tap(find.text('Volver al incidente'));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
    expect(find.byType(TriageDialog), findsNothing);
  });

  testWidgets('«Registrar siguiente» vuelve a asignar color', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Asignar color directo');
    await _pickAndSave(tester, 'Leve');
    await tester.tap(find.text('Registrar siguiente paciente'));
    await tester.pumpAndSettle();
    expect(find.text('Paciente 7 · INC-A1B2C3'), findsOneWidget);
  });

  testWidgets('Guardar espera a que se elija un color', (tester) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'Asignar color directo');
    final save = tester.widget<TriageButton>(
      find.widgetWithText(TriageButton, 'Guardar paciente'),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('usar el protocolo guiado abre START', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Asignar color directo');
    await _choose(tester, '¿No estás seguro? Usa el protocolo guiado');
    expect(h.legacy, ['start']);
    expect(find.byType(TriageSheet), findsNothing);
  });

  testWidgets('emergencias encadena pacientes sin cerrar el panel', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Emergencias');

    await _pickAndSave(tester, 'Inmediato');
    expect(find.text('Paciente 6 registrado con éxito'), findsOneWidget);
    expect(find.byType(TriageDialog), findsNothing);

    await _pickAndSave(tester, 'Fallecido');
    expect(find.text('Paciente 7 registrado con éxito'), findsOneWidget);
    expect(h.repo.registered.map((p) => p['triage']), ['rojo', 'negro']);
    expect(h.changes, 2);

    // Tras guardar, el color queda sin elegir
    final save = tester.widget<TriageButton>(
      find.widgetWithText(TriageButton, 'Guardar paciente'),
    );
    expect(save.onPressed, isNull);

    await tester.ensureVisible(find.text('Cancelar'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
  });

  testWidgets('emergencias se cierra con la X', (tester) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'Emergencias');
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
  });

  testWidgets('un error al guardar se muestra en el panel', (tester) async {
    final h = _Harness(repo: FakeIntakeRepository()..failWith = 'Sin red');
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Asignar color directo');
    await _pickAndSave(tester, 'Urgente');
    expect(find.text('No se pudo registrar al paciente'), findsOneWidget);
    expect(find.byType(TriageSheet), findsOneWidget);
    expect(h.changes, 0);
  });

  for (final (width, scale) in const [(280.0, 2.0), (393.0, 1.0)]) {
    testWidgets('paneles sin desbordes en $width al ${scale * 100} %', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_Harness().app(textScale: scale));
      await _open(tester);
      expect(tester.takeException(), isNull);
      await _choose(tester, 'Emergencias');
      expect(tester.takeException(), isNull);
    });
  }
}
