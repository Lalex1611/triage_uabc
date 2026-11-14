import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_geocoding_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_route_service.dart';

/// Geocodificador que responde cuando el test lo decide
class _ManualGeocoding extends MapGeocodingService {
  final requests = <String, Completer<LatLng?>>{};

  @override
  Future<LatLng?> search(String query, {LatLng? near}) =>
      (requests[query] = Completer<LatLng?>()).future;
}

/// Servicio de rutas que responde cuando el test lo decide
class _ManualRoutes extends MapRouteService {
  final reply = Completer<List<LatLng>>();

  @override
  Future<List<LatLng>> fetchDrivingRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) => reply.future;
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

  test('una ruta que llega tras soltar el incidente no se pinta', () async {
    final routes = _ManualRoutes();
    final c = ParamedicoMapController(routeService: routes);
    addTearDown(c.dispose);
    c.userPosition = const LatLng(32.5, -117);
    c.selectedIncidentId = 'a';

    final pending = c.loadRouteTo(
      ParamedicoIncidentSummary(
        id: 'a',
        generatedTitle: 'a',
        emergencyType: 'otro',
        createdAt: null,
        createdBy: 'u',
        latitude: 32.51,
        longitude: -117.01,
      ),
    );
    c.clearSelection();
    routes.reply.complete(const [LatLng(32.5, -117), LatLng(32.51, -117.01)]);
    await pending;

    expect(c.routePoints, isEmpty);
    expect(c.routing, isFalse);
  });

  test('tras dispose, lo que termine tarde no avisa', () {
    final c = ParamedicoMapController()..dispose();
    expect(() => c.setShowIncidents(false), returnsNormally);
  });
}
