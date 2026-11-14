import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/util/map_launcher.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
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

  test('desde la ficha de un paciente se puede volver a ella', () {
    final c = _controller();
    addTearDown(c.dispose);

    c.focusIncidentForView(_incident('a'), highlightPatientId: 'p');
    expect(c.highlightedPatientId, 'p');
    expect(c.returnToPatientId, 'p');

    // Elegir otro incidente ya no tiene que ver con ese paciente
    c.onPinTap(_incident('b'));
    expect(c.highlightedPatientId, isNull);
    expect(c.returnToPatientId, isNull);
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
