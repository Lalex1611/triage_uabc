import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_incidents_store.dart';

ParamedicoIncidentSummary _incident(String id) => ParamedicoIncidentSummary(
  id: id,
  generatedTitle: id,
  emergencyType: 'otro',
  createdAt: null,
  createdBy: 'u',
  latitude: 32.5,
  longitude: -117,
);

/// Supabase de mentira: [incidents] es lo que hay "en la base" en cada momento
class _FakeRepository extends ParamedicoIncidentsRepository {
  List<ParamedicoIncidentSummary> incidents = [];
  int loads = 0;
  bool fail = false;
  Completer<void>? gate;
  void Function()? onChange;
  void Function()? onSubscribed;
  bool unwatched = false;

  @override
  Future<List<ParamedicoIncidentSummary>> listOpenIncidents() async {
    loads++;
    final snapshot = List.of(incidents);
    final wait = gate;
    if (wait != null) await wait.future;
    if (fail) throw Exception('sin red');
    return snapshot;
  }

  @override
  Future<
    ({Map<String, IncidentPatientTriageCounts> counts, List<MapPatientPin> pins})
  >
  patientsOverviewForIncidents(
    Iterable<String> incidentIds, {
    Map<String, LatLng> incidentCentersById = const {},
  }) async => (
    counts: <String, IncidentPatientTriageCounts>{},
    pins: <MapPatientPin>[],
  );

  @override
  Future<void> Function() watchIncidentsAndPatients({
    required void Function() onChange,
    required void Function() onSubscribed,
  }) {
    this.onChange = onChange;
    this.onSubscribed = onSubscribed;
    return () async => unwatched = true;
  }
}

List<String> _ids(ParamedicoIncidentsStore store) =>
    [for (final e in store.incidents) e.id];

void main() {
  late _FakeRepository repo;
  late ParamedicoIncidentsStore store;

  setUp(() {
    repo = _FakeRepository()..incidents = [_incident('a'), _incident('b')];
    store = ParamedicoIncidentsStore(repository: repo);
  });

  testWidgets('el mapa y la lista comparten una sola carga', (tester) async {
    store.addListener(() {});
    store.addListener(() {});
    await tester.pump();
    expect(repo.loads, 1);
    expect(store.loaded, isTrue);
    expect(_ids(store), ['a', 'b']);
  });

  testWidgets('un cambio en tiempo real recarga una vez y quita el cerrado', (
    tester,
  ) async {
    store.addListener(() {});
    await tester.pump();

    repo.incidents = [_incident('a')]; // "b" se cerró en otro dispositivo
    for (var i = 0; i < 3; i++) {
      repo.onChange!();
    }
    await tester.pump(ParamedicoIncidentsStore.changeDebounce ~/ 2);
    expect(repo.loads, 1, reason: 'espera a que pase la ráfaga');
    await tester.pump(ParamedicoIncidentsStore.changeDebounce);
    expect(repo.loads, 2);
    expect(_ids(store), ['a']);
  });

  testWidgets('recarga al activarse la suscripción y al reconectar', (
    tester,
  ) async {
    store.addListener(() {});
    await tester.pump();
    // Lo que cambió entre la carga inicial y la suscripción no avisó
    repo.onSubscribed!();
    await tester.pump(ParamedicoIncidentsStore.changeDebounce * 2);
    expect(repo.loads, 2);
    repo.onSubscribed!();
    await tester.pump(ParamedicoIncidentsStore.changeDebounce * 2);
    expect(repo.loads, 3);
  });

  testWidgets('con cambios continuos la recarga no se aplaza sin fin', (
    tester,
  ) async {
    store.addListener(() {});
    await tester.pump();
    // Un cambio cada tercio de la espera, durante el doble de la espera
    for (var i = 0; i < 6; i++) {
      repo.onChange!();
      await tester.pump(ParamedicoIncidentsStore.changeDebounce ~/ 3);
    }
    expect(repo.loads, greaterThanOrEqualTo(2));
    await tester.pump(ParamedicoIncidentsStore.changeDebounce);
  });

  testWidgets('lo que cargaba una sesión anterior no se publica en la nueva', (
    tester,
  ) async {
    final gate = Completer<void>();
    repo.gate = gate;
    void previous() {}
    store.addListener(previous); // Lee a y b y se queda esperando
    store.removeListener(previous); // Cierra sesión
    repo.gate = null;
    repo.incidents = [_incident('c')];

    final seen = <List<String>>[];
    store.addListener(() => seen.add(_ids(store))); // Nueva sesión
    gate.complete();
    await tester.pump();
    await tester.pump();

    expect(seen, isNot(contains(['a', 'b'])));
    expect(_ids(store), ['c']);
  });

  testWidgets('pedir recarga durante otra espera a una carga nueva', (
    tester,
  ) async {
    final gate = Completer<void>();
    repo.gate = gate;
    store.addListener(() {}); // Esta carga lee a y b y se queda esperando
    repo.gate = null;
    repo.incidents = [_incident('a'), _incident('b'), _incident('c')];

    // Quien acaba de crear "c" pide recargar y espera verlo
    final refreshed = store.refresh();
    gate.complete();
    await refreshed;

    expect(repo.loads, 2);
    expect(_ids(store), ['a', 'b', 'c']);
  });

  testWidgets('si falla una recarga se conserva lo que había', (tester) async {
    store.addListener(() {});
    await tester.pump();
    repo.fail = true;
    await store.refresh();
    expect(_ids(store), ['a', 'b']);
    expect(store.error, isNull);
  });

  testWidgets('si nunca cargó, muestra el error', (tester) async {
    repo.fail = true;
    store.addListener(() {});
    await tester.pump();
    expect(store.loaded, isFalse);
    expect(store.error, contains('sin red'));
  });

  testWidgets('sin nadie escuchando se desuscribe y olvida los datos', (
    tester,
  ) async {
    void listener() {}
    store.addListener(listener);
    await tester.pump();
    store.removeListener(listener);
    expect(repo.unwatched, isTrue);
    expect(store.incidents, isEmpty);
    expect(store.loaded, isFalse);
  });
}
