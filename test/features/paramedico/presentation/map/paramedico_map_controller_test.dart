import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/util/map_launcher.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_geocoding_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_incidents_store.dart';

/// Geocodificador que responde cuando el test lo decide
class _ManualGeocoding extends MapGeocodingService {
  final requests = <String, Completer<LatLng?>>{};

  @override
  Future<LatLng?> search(String query, {LatLng? near}) =>
      (requests[query] = Completer<LatLng?>()).future;
}

ParamedicoIncidentSummary _incident(String id) => ParamedicoIncidentSummary(
  id: id,
  generatedTitle: id,
  emergencyType: 'otro',
  createdAt: null,
  createdBy: 'u',
  latitude: 32.51,
  longitude: -117.01,
);

/// La recarga devuelve "c" (recién creado) cuando el test abre [gate]
class _GatedRepository extends ParamedicoIncidentsRepository {
  final gate = Completer<void>();

  @override
  Future<List<ParamedicoIncidentSummary>> listOpenIncidents() async {
    await gate.future;
    return [_incident('a'), _incident('b'), _incident('c')];
  }

  @override
  Future<
    ({
      Map<String, IncidentPatientTriageCounts> counts,
      List<MapPatientPin> pins,
    })
  >
  patientsOverviewForIncidents(
    Iterable<String> incidentIds, {
    Map<String, LatLng> incidentCentersById = const {},
  }) async => (
    counts: <String, IncidentPatientTriageCounts>{},
    pins: <MapPatientPin>[],
  );
}

/// Incidentes "en la base" que el test cambia entre recargas
class _ListRepository extends ParamedicoIncidentsRepository {
  _ListRepository(this.incidents);

  List<ParamedicoIncidentSummary> incidents;

  @override
  Future<List<ParamedicoIncidentSummary>> listOpenIncidents() async =>
      List.of(incidents);

  @override
  Future<
    ({
      Map<String, IncidentPatientTriageCounts> counts,
      List<MapPatientPin> pins,
    })
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
  }) => () async {};
}

/// Cámara de mentira: anota cada operación y puede fallar las primeras.
/// [camera] queda donde la dejó el último `move`
class _FakeMap implements MapController {
  final calls = <Symbol>[];
  final moves = <LatLng>[];
  int failures = 0;
  LatLng center = const LatLng(0, 0);
  double zoom = 0;

  @override
  MapCamera get camera => MapCamera(
    crs: const Epsg3857(),
    center: center,
    zoom: zoom,
    rotation: 0,
    nonRotatedSize: const Size(400, 800),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #dispose) return null;
    if (failures > 0) {
      failures--;
      throw StateError('El mapa aún no tiene tamaño');
    }
    calls.add(invocation.memberName);
    if (invocation.memberName == #move) {
      center = invocation.positionalArguments[0] as LatLng;
      zoom = invocation.positionalArguments[1] as double;
      moves.add(center);
    }
    return true;
  }
}

/// GPS de mentira: con permiso, [lastKnown] al instante y la lectura nueva
/// cuando el test complete [current]. Cuenta las lecturas pedidas
class _Gps {
  _Gps({this.lastKnown}) {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 2; // Mientras se usa la app
        case 'getLastKnownPosition':
          return lastKnown == null ? null : _position(lastKnown!);
        case 'getCurrentPosition':
          reads++;
          final fix = await current.future;
          return fix == null ? null : _position(fix);
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  final LatLng? lastKnown;
  final current = Completer<LatLng?>();
  int reads = 0;

  static Map<String, Object> _position(LatLng p) => {
    'latitude': p.latitude,
    'longitude': p.longitude,
    'timestamp': 0,
  };
}

/// Flujo de posiciones en vivo: el test emite por [sink], que es null cuando
/// nadie escucha. [listens] cuenta las veces que se encendió
class _LiveGps {
  _LiveGps() {
    const channel = EventChannel('flutter.baseflow.com/geolocator_updates');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (_, events) {
          sink = events;
          listens++;
        },
        onCancel: (_) => sink = null,
      ),
    );
    addTearDown(() => messenger.setMockStreamHandler(channel, null));
  }

  MockStreamHandlerEventSink? sink;
  int listens = 0;
}

/// Sin GPS en los tests: el servicio de ubicación dice que está apagado
void _gpsOff() {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (_) async => false);
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return context;
}

/// Controlador con dos incidentes cargados (sin Supabase ni GPS)
ParamedicoMapController _controller() {
  final store = ParamedicoIncidentsStore()
    ..incidents = [_incident('a'), _incident('b')];
  return ParamedicoMapController(store: store);
}

void main() {
  test('"Cerca de mí" incluye hasta 5 km y deja fuera lo que pasa de ahí', () {
    const user = LatLng(32.5149, -117.0382);
    const distance = Distance();
    LatLng at(double meters) => distance.offset(user, meters, 45);

    expect(ParamedicoMapController.isNearby(user, at(4900)), isTrue);
    expect(ParamedicoMapController.isNearby(user, at(5100)), isFalse);
  });

  testWidgets('una búsqueda anterior que responde tarde no se aplica', (
    tester,
  ) async {
    final geocoding = _ManualGeocoding();
    final c = ParamedicoMapController(geocodingService: geocoding);
    addTearDown(c.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    unawaited(c.searchAddress(context, 'vieja'));
    unawaited(c.searchAddress(context, 'nueva'));
    geocoding.requests['nueva']!.complete(const LatLng(32.5, -117));
    geocoding.requests['vieja']!.complete(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Si se aplicara la vieja, avisaría de que no encontró la dirección
    expect(find.textContaining('No encontramos'), findsNothing);
  });

  test('tocar un incidente lo elige y tocar el mapa lo suelta', () {
    final c = _controller();
    addTearDown(c.dispose);

    c.onPinTap(_incident('a'));
    expect(c.selectedIncident?.id, 'a');

    c.onMapBackgroundTap();
    expect(c.selectedIncidentId, isNull);
  });

  testWidgets('soltar el incidente o volver a «Todos» no mueve el mapa', (
    tester,
  ) async {
    final map = _FakeMap();
    final c = ParamedicoMapController(
      store: ParamedicoIncidentsStore()..incidents = [_incident('a')],
      mapController: map,
    )..markMapReady();
    addTearDown(c.dispose);
    final context = await _pumpContext(tester);
    c.userPosition = const LatLng(32.51, -117.01);

    c.onPinTap(_incident('a'));
    c.onMapBackgroundTap();
    expect(map.calls, isEmpty, reason: 'el usuario sigue donde estaba');

    await c.setFilter(context, MapIncidentFilter.nearby);
    map.calls.clear(); // «Cerca de mí» sí encuadra su círculo
    await c.setFilter(context, MapIncidentFilter.all);
    expect(map.calls, isEmpty);
  });

  testWidgets('desde la ficha de un paciente se puede volver a ella', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);

    c.focusIncidentForView(_incident('a'), highlightPatientId: 'p');
    await tester.pump();
    expect(c.highlightedPatientId, 'p');
    expect(c.returnToPatientId, 'p');

    // Elegir otro incidente ya no tiene que ver con ese paciente
    c.onPinTap(_incident('b'));
    expect(c.highlightedPatientId, isNull);
    expect(c.returnToPatientId, isNull);
  });

  testWidgets('un enfoque pendiente no pisa el incidente que se tocó después', (
    tester,
  ) async {
    final repo = _GatedRepository();
    final store = ParamedicoIncidentsStore(repository: repo)
      ..incidents = [_incident('a'), _incident('b')];
    final c = ParamedicoMapController(store: store);
    addTearDown(c.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );

    // "c" aún no llegó: el enfoque espera a que se recarguen los datos
    c.pendingFocusId = 'c';
    final focus = c.applyPendingFocus(context);
    c.onPinTap(_incident('b'));
    repo.gate.complete();
    await focus;

    expect(c.selectedIncidentId, 'b');
  });

  group('si se cierra el incidente elegido', () {
    /// Elige "a", lo cierra (aquí si [here], como hace B07) y devuelve
    /// cuántas veces avisó el mapa
    Future<int> closeA(WidgetTester tester, {bool here = false}) async {
      _gpsOff();
      final repo = _ListRepository([_incident('a'), _incident('b')]);
      final store = ParamedicoIncidentsStore(repository: repo);
      var notices = 0;
      final c = ParamedicoMapController(store: store)
        ..onSelectedIncidentClosed = () => notices++;
      addTearDown(c.dispose);
      c.init();
      await tester.pump();
      c.onPinTap(_incident('a'));

      if (here) store.closedHere.add('a');
      repo.incidents = [_incident('b')];
      await store.refresh();
      expect(c.selectedIncidentId, isNull);
      return notices;
    }

    testWidgets('en otro dispositivo: se suelta y se avisa', (tester) async {
      expect(await closeA(tester), 1);
    });

    testWidgets('desde este dispositivo: se suelta sin repetir el aviso', (
      tester,
    ) async {
      expect(await closeA(tester, here: true), 0);
    });
  });

  testWidgets('lo pedido antes de que el mapa esté listo se hace todo', (
    tester,
  ) async {
    final map = _FakeMap();
    final c = ParamedicoMapController(
      store: ParamedicoIncidentsStore(),
      mapController: map,
    )..userPosition = const LatLng(32.5, -117);
    addTearDown(c.dispose);
    final context = await _pumpContext(tester);

    c.goToRegionOverview(); // Encuadre inicial
    await c.setFilter(context, MapIncidentFilter.nearby);
    expect(map.calls, isEmpty);

    c.markMapReady();
    // Antes solo se guardaba la última y el encuadre inicial se perdía
    expect(map.calls, contains(#move));
    expect(map.calls, contains(#fitCamera));
  });

  testWidgets('un fallo de la cámara se reintenta y no congela el mapa', (
    tester,
  ) async {
    final map = _FakeMap()..failures = 1;
    final c = ParamedicoMapController(
      store: ParamedicoIncidentsStore(),
      mapController: map,
    );
    addTearDown(c.dispose);
    c.markMapReady();

    c.goToRegionOverview();
    expect(map.calls, isEmpty);
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(map.calls, [#rotate, #move], reason: 'reintento al siguiente frame');

    // Antes el mapa quedaba «no listo» para siempre y esto no llegaba
    c.goToRegionOverview();
    expect(map.calls, [#rotate, #move, #rotate, #move]);
  });

  group('botón «Objetivo»', () {
    const known = LatLng(32.50, -117.00);
    const fresh = LatLng(32.51, -117.01);

    Future<(ParamedicoMapController, _FakeMap, BuildContext)> setUpMap(
      WidgetTester tester,
    ) async {
      final map = _FakeMap();
      final c = ParamedicoMapController(
        store: ParamedicoIncidentsStore(),
        mapController: map,
      )..markMapReady();
      addTearDown(c.dispose);
      return (c, map, await _pumpContext(tester));
    }

    testWidgets('centra al instante en lo conocido y luego afina', (
      tester,
    ) async {
      final gps = _Gps();
      final (c, map, context) = await setUpMap(tester);
      c.userPosition = known;

      final done = c.centerOnUser(context);
      await tester.pump();
      expect(map.moves, [known], reason: 'sin esperar al GPS');

      gps.current.complete(fresh);
      await done;
      expect(map.moves, [known, fresh]);
      expect(c.userPosition, fresh);
    });

    testWidgets(
      'si el usuario movió el mapa, la lectura nueva no lo arrastra',
      (tester) async {
        final gps = _Gps();
        final (c, map, context) = await setUpMap(tester);
        c.userPosition = known;

        final done = c.centerOnUser(context);
        await tester.pump();
        map.center = const LatLng(32.6, -117.1); // Lo arrastró mientras tanto
        gps.current.complete(fresh);
        await done;

        expect(map.moves, [known]);
        expect(c.userPosition, fresh, reason: 'el punto sí se actualiza');
      },
    );

    testWidgets('usa la última posición del sistema si el mapa no tiene una', (
      tester,
    ) async {
      final gps = _Gps(lastKnown: known);
      final (c, map, context) = await setUpMap(tester);

      final done = c.centerOnUser(context);
      await tester.pump();
      expect(map.moves, [known]);
      expect(c.locating, isFalse);

      gps.current.complete(null); // El GPS no responde
      await done;
      expect(
        c.userPosition,
        isNull,
        reason: 'una posición guardada no vale para «Cerca de mí»',
      );
    });

    testWidgets(
      'sin nada conocido, si el usuario mueve el mapa, el GPS no lo arrastra',
      (tester) async {
        final gps = _Gps();
        final (c, map, context) = await setUpMap(tester);

        final done = c.centerOnUser(context);
        await tester.pump();
        map.center = const LatLng(32.6, -117.1); // Lo arrastró mientras tanto
        gps.current.complete(fresh);
        await done;

        expect(map.moves, isEmpty);
        expect(c.userPosition, fresh);
      },
    );

    testWidgets('sin nada conocido espera al GPS y no repite la búsqueda', (
      tester,
    ) async {
      final gps = _Gps();
      final (c, map, context) = await setUpMap(tester);

      final done = c.centerOnUser(context);
      await tester.pump();
      expect(c.locating, isTrue);
      expect(map.moves, isEmpty);

      await c.centerOnUser(context); // Segundo toque mientras busca
      expect(gps.reads, 1);

      gps.current.complete(fresh);
      await done;
      expect(map.moves, [fresh]);
      expect(c.locating, isFalse);
    });
  });

  group('posición en vivo', () {
    ParamedicoMapController liveController(_FakeMap map) {
      final c = ParamedicoMapController(
        store: ParamedicoIncidentsStore(),
        mapController: map,
      )..markMapReady();
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('mueve el punto, no la cámara, y se apaga al ocultar el mapa', (
      tester,
    ) async {
      final live = _LiveGps();
      final map = _FakeMap();
      final c = liveController(map);

      c.setLiveLocation(true);
      await tester.pump();
      live.sink!.success(_Gps._position(const LatLng(32.5, -117.0)));
      await tester.pump();
      expect(c.userPosition, const LatLng(32.5, -117.0));
      expect(map.moves, isEmpty);

      c.setLiveLocation(false);
      await tester.pump();
      expect(live.sink, isNull, reason: 'GPS apagado');
    });

    testWidgets('si el GPS falla se para y lo reintenta al volver al mapa', (
      tester,
    ) async {
      final live = _LiveGps();
      final c = liveController(_FakeMap());

      c.setLiveLocation(true);
      await tester.pump();
      live.sink!.error(code: 'PERMISSION_DENIED');
      await tester.pump();
      expect(live.sink, isNull);

      c.setLiveLocation(true);
      await tester.pump();
      expect(live.listens, 2);
    });
  });

  test('pacientes y radios se calculan con la cámara que se les pasa', () {
    final c = _controller();
    addTearDown(c.dispose);
    final far = MapCamera(
      crs: const Epsg3857(),
      center: const LatLng(32.51, -117.01),
      zoom: 3,
      rotation: 0,
      nonRotatedSize: const Size(400, 800),
    );

    // Lejos y sin elegir: ni radios ni pacientes
    expect(c.visibleCoverageRings(far), isEmpty);
    // Elegido: su radio se ve aunque la cámara esté lejos
    c.onPinTap(_incident('a'));
    expect(c.visibleCoverageRings(far), hasLength(1));
  });

  test('"Cómo llegar" abre Google Maps navegando al incidente', () {
    final uri = directionsUri(32.51, -117.01);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {
      'api': '1',
      'destination': '32.51,-117.01',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
    // Sin origen: Google Maps sale de donde esté el usuario en ese momento
    expect(uri.queryParameters.containsKey('origin'), isFalse);
  });

  test('tras dispose, lo que termine tarde no avisa', () {
    final c = ParamedicoMapController()..dispose();
    expect(() => c.setShowIncidents(false), returnsNormally);
  });
}
