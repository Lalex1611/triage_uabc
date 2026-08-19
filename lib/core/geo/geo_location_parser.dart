import 'dart:convert';
import 'dart:typed_data';

/// Parseo de `location` PostGIS / GeoJSON para mostrar lat,lng en UI
class GeoLocationParser {
  GeoLocationParser._();

  static (double lat, double lng)? parse(dynamic location) =>
      _coordsFromLocationField(location);

  static String formatForDisplay(
    dynamic location, {
    int decimals = 5,
    String fallback = '—',
  }) {
    final coords = parse(location);
    if (coords == null) return fallback;
    final lat = coords.$1.toStringAsFixed(decimals);
    final lng = coords.$2.toStringAsFixed(decimals);
    return '$lat, $lng';
  }

  static (double, double)? _coordsFromLocationField(dynamic location) {
    if (location == null) return null;

    if (location is String) {
      final s = location.trim();
      if (s.isEmpty) return null;
      if (s.startsWith('{')) {
        try {
          return _coordsFromLocationField(jsonDecode(s));
        } catch (_) {
          return null;
        }
      }
      final m = RegExp(
        r'POINT\s*\(\s*([-\d.eE+]+)\s+([-\d.eE+]+)\s*\)',
        caseSensitive: false,
      ).firstMatch(s);
      if (m != null) {
        final lng = double.tryParse(m.group(1)!);
        final lat = double.tryParse(m.group(2)!);
        if (lng != null && lat != null) return (lat, lng);
      }
      if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) {
        return _coordsFromEwkbHex(s);
      }
      return null;
    }

    if (location is Map) {
      final c = location['coordinates'];
      if (c is List && c.length >= 2) {
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        return (lat, lng);
      }
    }
    return null;
  }

  static (double, double)? _coordsFromEwkbHex(String hex) {
    final cleaned = hex.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length < 42 || cleaned.length.isOdd) return null;
    try {
      final bytes = Uint8List(cleaned.length ~/ 2);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
      }
      final endian = bytes[0] == 1 ? Endian.little : Endian.big;
      final data = ByteData.sublistView(bytes);
      var offset = 1;
      final wkbType = data.getUint32(offset, endian);
      offset += 4;
      if ((wkbType & 0x20000000) != 0) {
        offset += 4;
      }
      if ((wkbType & 0xff) != 1) return null;
      final lng = data.getFloat64(offset, endian);
      offset += 8;
      final lat = data.getFloat64(offset, endian);
      if (!lat.isFinite || !lng.isFinite) return null;
      return (lat, lng);
    } catch (_) {
      return null;
    }
  }
}
