import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_triage/core/geo/nominatim_reverse_geocode.dart';

void main() {
  late List<DateTime> starts;

  setUp(() {
    starts = [];
    NominatimReverseGeocode.debugClient = MockClient((request) async {
      starts.add(DateTime.now());
      return http.Response(
        jsonEncode({
          'address': {'road': 'Blvd. Díaz Ordaz', 'house_number': '1540'},
        }),
        200,
      );
    });
  });
  tearDown(NominatimReverseGeocode.debugReset);

  test(
    'la primera petición sale enseguida y devuelve calle y número',
    () async {
      final before = DateTime.now();
      expect(
        await NominatimReverseGeocode.shortPlaceLabel(32.48, -116.93),
        'Blvd. Díaz Ordaz 1540',
      );
      expect(
        starts.single.difference(before),
        lessThan(const Duration(milliseconds: 500)),
      );
    },
  );

  test('peticiones seguidas, vengan de donde vengan, empiezan con al menos un '
      'segundo de diferencia y en orden', () async {
    final results = await Future.wait([
      NominatimReverseGeocode.shortPlaceLabel(32.48, -116.93),
      NominatimReverseGeocode.shortPlaceLabel(32.49, -116.94),
      NominatimReverseGeocode.shortPlaceLabel(32.50, -116.95),
    ]);

    expect(results, everyElement('Blvd. Díaz Ordaz 1540'));
    expect(starts, hasLength(3));
    for (var i = 1; i < starts.length; i++) {
      expect(
        starts[i].difference(starts[i - 1]),
        greaterThanOrEqualTo(NominatimReverseGeocode.minInterval),
      );
    }
  });

  test('si falla la red devuelve null y no bloquea las siguientes', () async {
    NominatimReverseGeocode.debugClient = MockClient(
      (_) async => throw http.ClientException('sin red'),
    );
    expect(
      await NominatimReverseGeocode.shortPlaceLabel(32.48, -116.93),
      isNull,
    );

    NominatimReverseGeocode.debugClient = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'address': {'suburb': 'La Mesa'},
        }),
        200,
      ),
    );
    expect(
      await NominatimReverseGeocode.shortPlaceLabel(32.48, -116.93),
      'La Mesa',
    );
  });
}
