import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Nominatim (OSM): nombre corto de vía para títulos de incidente
/// Política de uso: https://operations.osmfoundation.org/policies/nominatim/
class NominatimReverseGeocode {
  NominatimReverseGeocode._();

  static const _ua =
      'SistemaTriage/1.0 (paramedico-incident-title; contacto institucional)';

  /// La política permite como mucho una petición por segundo
  static const minInterval = Duration(seconds: 1);

  /// Cola de turnos: cada petición empieza al menos [minInterval] después de
  /// la anterior, la pidan el modal, la hoja o el registro de pacientes
  static Future<void> _queue = Future.value();
  static DateTime? _lastStart;

  @visibleForTesting
  static http.Client? debugClient;

  @visibleForTesting
  static void debugReset() {
    _queue = Future.value();
    _lastStart = null;
    debugClient = null;
  }

  /// Devuelve algo legible (calle + número o barrio) o `null` si falla
  static Future<String?> shortPlaceLabel(double lat, double lng) async {
    final turn = _queue.then((_) async {
      final last = _lastStart;
      if (last != null) {
        final wait = minInterval - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastStart = DateTime.now();
    });
    _queue = turn;
    await turn;
    return _fetch(lat, lng);
  }

  static Future<String?> _fetch(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'json',
      'addressdetails': '1',
      'zoom': '18',
    });
    try {
      final headers = {'User-Agent': _ua, 'Accept-Language': 'es'};
      final client = debugClient;
      final res = client != null
          ? await client.get(uri, headers: headers)
          : await http.get(uri, headers: headers);
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>?;
      if (j == null) return null;
      final addr = j['address'];
      if (addr is! Map<String, dynamic>) return null;
      final road = addr['road'] as String?;
      final house = addr['house_number'] as String?;
      final suburb =
          addr['suburb'] as String? ?? addr['neighbourhood'] as String?;
      if (road != null && road.isNotEmpty) {
        final h = house != null && house.isNotEmpty ? ' $house' : '';
        return '$road$h'.trim();
      }
      if (suburb != null && suburb.isNotEmpty) return suburb;
      final city = addr['city'] as String? ?? addr['town'] as String?;
      if (city != null && city.isNotEmpty) return city;
      return null;
    } catch (_) {
      return null;
    }
  }
}
