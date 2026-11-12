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

/// Caja de un `TriageField` o `TriageSelectField`: la etiqueta va encima, en
/// el mismo nodo semántico
Finder _field(String label, Finder box) => find.descendant(
  of: find
      .ancestor(of: find.text(label), matching: find.byType(MergeSemantics))
      .first,
  matching: box,
);

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = _field(label, find.byType(TextFormField));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _select(WidgetTester tester, String label, String option) async {
  final field = _field(
    label,
    find.byWidgetPredicate((w) => w is DropdownButtonFormField),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
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

  testWidgets('Registro extendido guarda los datos que lee la ficha', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Registro extendido');
    expect(find.byType(TriageSheet), findsOneWidget);
    expect(find.text('Paciente 6 · INC-A1B2C3'), findsOneWidget);
    final save = find.widgetWithText(TriageButton, 'Guardar paciente');
    expect(tester.widget<TriageButton>(save).onPressed, isNull);

    await _choose(tester, 'Urgente');
    await _type(tester, 'Nombre o alias', 'Bruce Cervantes');
    await _type(tester, 'Edad', '22');
    await _select(tester, 'Sexo', 'Masculino');
    await _select(tester, 'Tipo de sangre', 'O+');
    await _type(tester, 'Teléfono de contacto', '664 123 4567');
    await _type(tester, 'Descripción', 'Hemorragia en muslo derecho');
    await _choose(tester, 'Hemorragia');
    await _choose(tester, 'Guardar paciente');

    final saved = h.repo.registered.single;
    expect(saved['triage'], 'amarillo');
    expect(saved['name'], 'Bruce Cervantes');
    expect(saved['demographics'], {
      'description': 'Hemorragia en muslo derecho',
      'injury_types': ['hemorragia'],
      'gender': 'masculino',
      'blood_type': 'oPositivo',
      'birth_year': DateTime.now().year - 22,
      'emergency_contact': '664 123 4567',
      'photo_local_paths': <String>[],
    });
    expect(h.changes, 1);
    expect(find.text('PAC-ABCDEF quedó registrado'), findsOneWidget);
    expect(find.byType(TriageSheet), findsNothing);
  });

  testWidgets('Registro extendido: una edad no válida impide guardar', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'Registro extendido');
    await _choose(tester, 'Leve');
    await _type(tester, 'Edad', '200');
    expect(find.text('Escribe la edad en años'), findsOneWidget);
    final save = find.widgetWithText(TriageButton, 'Guardar paciente');
    expect(tester.widget<TriageButton>(save).onPressed, isNull);
  });

  testWidgets('Registro extendido con datos pide confirmación al salir', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Registro extendido');
    await _type(tester, 'Nombre o alias', 'Ana');
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin registrar?'), findsOneWidget);
    await tester.tap(find.text('Salir y perder los datos'));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
    expect(h.repo.registered, isEmpty);
  });

  testWidgets('Registro extendido vacío se cierra sin preguntar', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'Registro extendido');
    await _choose(tester, 'Cancelar');
    expect(find.text('¿Salir sin registrar?'), findsNothing);
    expect(find.byType(TriageSheet), findsNothing);
  });

  testWidgets('START guiado: cinco respuestas, registro y diálogo', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    expect(find.text('Paso 1 de 5'), findsOneWidget);
    expect(find.text('Paciente 6 · INC-A1B2C3'), findsOneWidget);

    for (final answer in [
      'No camina',
      'Sí respira',
      '30 o menos',
      'Llenado de 2 s o menos',
      'Sí obedece',
    ]) {
      await _choose(tester, answer);
    }
    expect(find.text('Amarillo · Urgente'), findsOneWidget);
    expect(find.text('Por qué salió amarillo'), findsOneWidget);
    expect(find.text('2 s o menos'), findsOneWidget);

    await _choose(tester, 'Guardar paciente');
    expect(h.repo.registered.single['triage'], 'amarillo');
    final demo = h.repo.registered.single['demographics']! as Map;
    expect(demo['start_triage_mode'], 'protocoloGuiado');
    expect(find.text('PAC-ABCDEF quedó registrado'), findsOneWidget);
    expect(find.byType(TriageSheet), findsNothing);

    await tester.tap(find.text('Registrar siguiente paciente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 5'), findsOneWidget);
    expect(find.text('Paciente 7 · INC-A1B2C3'), findsOneWidget);
  });

  testWidgets('START guiado: no respirar ni al abrir la vía aérea es negro', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    await _choose(tester, 'No camina');
    await _choose(tester, 'No respira ni al abrir la vía aérea');
    expect(find.text('Negro · Fallecido'), findsOneWidget);
  });

  testWidgets('START guiado: respirar solo al abrir la vía aérea es rojo', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    await _choose(tester, 'No camina');
    await _choose(tester, 'Respira solo al abrir la vía aérea');
    expect(find.text('Rojo · Inmediato'), findsOneWidget);
    expect(find.text('Solo al abrir la vía aérea'), findsOneWidget);
  });

  testWidgets('START guiado: un doble toque responde una sola pregunta', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    // Dos toques antes de redibujar
    await tester.tap(find.text('No camina'));
    await tester.tap(find.text('No camina'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 5'), findsOneWidget);
    expect(find.text('¿Respira?'), findsOneWidget);
  });

  testWidgets('START guiado sin conexión: se responde y guarda al volver', (
    tester,
  ) async {
    final h = _Harness(
      repo: FakeIntakeRepository()..incidentError = 'Sin conexión',
    );
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    // Sin número de paciente mientras no se pudo leer el incidente
    expect(find.text('INC-A1B2C3'), findsOneWidget);
    expect(find.textContaining('Paciente'), findsNothing);

    await _choose(tester, 'Sí, camina');
    await _choose(tester, 'Guardar paciente');
    expect(find.text('No se pudo registrar al paciente'), findsOneWidget);
    expect(h.repo.registered, isEmpty);

    h.repo.incidentError = null;
    await _choose(tester, 'Guardar paciente');
    expect(h.repo.registered.single['triage'], 'verde');
    expect(find.text('PAC-ABCDEF quedó registrado'), findsOneWidget);
  });

  testWidgets('Asignar color sin conexión avisa y no abre el panel', (
    tester,
  ) async {
    final h = _Harness(
      repo: FakeIntakeRepository()..incidentError = 'Sin conexión',
    );
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'Asignar color directo');
    expect(find.byType(TriageSheet), findsNothing);
    expect(find.textContaining('No se pudo preparar'), findsOneWidget);
  });

  testWidgets('START guiado: cambiar el color sugerido', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    await _choose(tester, 'Sí, camina');
    expect(find.text('CLASIFICACIÓN SUGERIDA'), findsOneWidget);
    await _choose(tester, 'No estoy de acuerdo · cambiar el color');
    await _choose(tester, 'Inmediato');
    expect(find.text('CLASIFICACIÓN ASIGNADA'), findsOneWidget);
    // Los motivos siguen explicando el color que salió
    expect(find.text('Por qué salió verde'), findsOneWidget);
    await _choose(tester, 'Guardar paciente');
    expect(h.repo.registered.single['triage'], 'rojo');
  });

  testWidgets('START guiado: salir con respuestas pide confirmación', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    await _choose(tester, 'No camina');

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin registrar?'), findsOneWidget);
    await tester.tap(find.text('Seguir registrando'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 5'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir y perder los datos'));
    await tester.pumpAndSettle();
    expect(find.byType(TriageSheet), findsNothing);
    expect(h.repo.registered, isEmpty);
  });

  testWidgets('START guiado sin respuestas se cierra sin preguntar', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin registrar?'), findsNothing);
    expect(find.byType(TriageSheet), findsNothing);
  });

  testWidgets('Omitir START abre Asignar color en su lugar', (tester) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'START guiado');
    await _choose(tester, 'Omitir y asignar el color yo mismo');
    expect(find.byType(TriageSheet), findsOneWidget);
    expect(find.text('Asignar color'), findsOneWidget);
  });

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

  testWidgets('usar el protocolo guiado abre START en su lugar', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness().app());
    await _open(tester);
    await _choose(tester, 'Asignar color directo');
    await _choose(tester, '¿No estás seguro? Usa el protocolo guiado');
    expect(find.byType(TriageSheet), findsOneWidget);
    expect(find.text('Paso 1 de 5'), findsOneWidget);
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

    testWidgets('START guiado sin desbordes en $width al ${scale * 100} %', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_Harness().app(textScale: scale));
      await _open(tester);
      await _choose(tester, 'START guiado');
      expect(tester.takeException(), isNull);
      await _choose(tester, 'Sí, camina');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Registro extendido sin desbordes en $width al ${scale * 100} %',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_Harness().app(textScale: scale));
        await _open(tester);
        await _choose(tester, 'Registro extendido');
        await _choose(tester, 'Hemorragia');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
