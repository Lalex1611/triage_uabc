import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_controller.dart';

/// Búsquedas de dirección que el test responde cuando quiere
class _Lookups {
  final calls = <({double lat, double lng, Completer<String?> answer})>[];

  Future<String?> call(double lat, double lng) {
    final answer = Completer<String?>();
    calls.add((lat: lat, lng: lng, answer: answer));
    return answer.future;
  }
}

void main() {
  test('el incidente se titula con la categoría elegida', () {
    final c = CreateIncidentController(placeLookup: (_, _) async => null);
    addTearDown(c.dispose);

    expect(c.title, 'Accidente vehicular');

    c.setEmergencyType('incendio_quemadura');
    expect(c.title, 'Incendio o Quemadura');

    c.setEmergencyType('otro');
    expect(c.title, 'Otro');
  });

  group('dirección del punto elegido', () {
    late _Lookups lookups;
    late CreateIncidentController c;

    setUp(() {
      lookups = _Lookups();
      c = CreateIncidentController(placeLookup: lookups.call);
    });

    Future<void> choose(double lat, double lng) {
      c
        ..lat = lat
        ..lng = lng;
      return c.refreshPlace();
    }

    test('un punto elegido mientras se busca otro tiene su propia búsqueda '
        'y la respuesta tardía del anterior no lo pisa', () async {
      addTearDown(c.dispose);
      final gps = choose(32.50, -117.00);
      final map = choose(32.53, -116.99);

      expect(lookups.calls.map((l) => (l.lat, l.lng)), [
        (32.50, -117.00),
        (32.53, -116.99),
      ]);

      lookups.calls[1].answer.complete('Vía Rápida Oriente');
      await map;
      lookups.calls[0].answer.complete('Blvd. Agua Caliente');
      await gps;

      expect(c.placeLabel, 'Vía Rápida Oriente');
      expect(c.refreshingPlace, isFalse);
    });

    test('mientras falta la última respuesta se sigue buscando', () async {
      addTearDown(c.dispose);
      final gps = choose(32.50, -117.00);
      final map = choose(32.53, -116.99);

      lookups.calls[0].answer.complete('Blvd. Agua Caliente');
      await gps;
      expect(c.refreshingPlace, isTrue);
      expect(c.placeLabel, isNull);

      lookups.calls[1].answer.complete('Vía Rápida Oriente');
      await map;
      expect(c.placeLabel, 'Vía Rápida Oriente');
      expect(c.refreshingPlace, isFalse);
    });

    test('cerrar la hoja a mitad de búsqueda no avisa a un controlador '
        'cerrado', () async {
      final pending = choose(32.50, -117.00);
      c.dispose();

      lookups.calls.single.answer.complete('Blvd. Agua Caliente');
      await expectLater(pending, completes);
    });
  });
}
