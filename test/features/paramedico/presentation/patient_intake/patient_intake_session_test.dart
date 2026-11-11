import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

import 'fake_intake_repository.dart';

void main() {
  PatientIntakeSession session(
    FakeIntakeRepository repo, {
    GeoPoint? device,
    void Function()? onPlace,
  }) => PatientIntakeSession(
    incidentId: 'a1b2c3d4',
    repository: repo,
    currentPosition: () async => device,
    placeLabel: (_, _) async {
      onPlace?.call();
      return 'Blvd. 2000';
    },
  );

  test('numera a partir de los pacientes del incidente', () async {
    final s = session(FakeIntakeRepository(existing: 5));
    await s.prepare();
    expect(s.nextNumber, 6);
    final first = await s.register(level: TriageLevel.red);
    final second = await s.register(level: TriageLevel.green);
    expect([first.number, second.number], [6, 7]);
    expect(s.registeredCount, 7);
  });

  test('consulta incidente y lugar una sola vez por sesión', () async {
    final repo = FakeIntakeRepository();
    var places = 0;
    final s = session(repo, onPlace: () => places++);
    for (var i = 0; i < 3; i++) {
      await s.register(level: TriageLevel.yellow);
    }
    expect(repo.incidentReads, 1);
    expect(places, 1);
  });

  test('usa la ubicación del dispositivo', () async {
    final repo = FakeIntakeRepository();
    await session(
      repo,
      device: (lat: 10, lng: 20),
    ).register(level: TriageLevel.red);
    expect(repo.registered.single['lat'], 10);
    expect(repo.registered.single['lng'], 20);
  });

  test('sin GPS, usa la ubicación del incidente', () async {
    final repo = FakeIntakeRepository();
    await session(repo).register(level: TriageLevel.red);
    expect(repo.registered.single['lat'], 32.5);
  });

  test('sin GPS ni ubicación del incidente, avisa sin guardar', () async {
    final repo = FakeIntakeRepository(hasLocation: false);
    await expectLater(
      session(repo).register(level: TriageLevel.red),
      throwsA(isA<Exception>()),
    );
    expect(repo.registered, isEmpty);
  });

  test('nombre propio o automático con número y lugar', () async {
    final repo = FakeIntakeRepository(existing: 2);
    final s = session(repo);
    await s.register(level: TriageLevel.red, name: '  Ana  ');
    await s.register(level: TriageLevel.red, name: ' ');
    expect(repo.registered[0]['name'], 'Ana');
    expect(repo.registered[1]['name'], startsWith('Paciente Numero 4 - '));
    expect(repo.registered[1]['name'], endsWith('Blvd. 2000'));
  });

  test('guarda color, fotos y origen del registro', () async {
    final repo = FakeIntakeRepository();
    final patient = await session(
      repo,
    ).register(level: TriageLevel.black, photos: ['/f.jpg']);
    expect(repo.registered.single['triage'], 'negro');
    final demo = repo.registered.single['demographics']! as Map;
    expect(demo['photo_local_paths'], ['/f.jpg']);
    expect(demo['registered_from_start'], isTrue);
    expect(patient.folio, 'PAC-ABCDEF');
  });

  test('si falla el guardado, no avanza el número', () async {
    final repo = FakeIntakeRepository()..failWith = Exception('sin red');
    final s = session(repo);
    await expectLater(s.register(level: TriageLevel.red), throwsException);
    expect(s.nextNumber, 6);
  });
}
