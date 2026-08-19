import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Contrato de la supabase
///
/// **Tablas:** `incidents`, `patients`, `consultation_codes`, `storage.objects` (bucket `patient_photos`)
///
/// **Columnas paciente (además del esquema base):** `display_name`, `demographics` (JSON: lesiones,
/// descripción, género, tipo de sangre, rutas locales de fotos hasta subir a Storage con prefijo
/// `{auth.uid()}/...` según políticas en `20260513120000_paramedico_patient_demographics.sql`)
///
/// **RPC:** `create_incident_for_paramedic` (título, enum `emergency_type`, punto PostGIS)
///
/// **Consultas típicas:** listado incidentes `status=activo`; pacientes por `incident_id`; conteos
/// triage agregados en cliente vía `patientTriageCountsByIncident`
class ParamedicoIncidentSummary {
  ParamedicoIncidentSummary({
    required this.id,
    required this.generatedTitle,
    required this.emergencyType,
    required this.createdAt,
    required this.createdBy,
    this.description,
    this.photoPaths = const [],
    this.latitude,
    this.longitude,
  });

  final String id;
  final String generatedTitle;
  final String emergencyType;
  final DateTime? createdAt;
  final String createdBy;
  final String? description;
  final List<String> photoPaths;
  final double? latitude;
  final double? longitude;

  factory ParamedicoIncidentSummary.fromJson(Map<String, dynamic> j) {
    final loc = j['location'];
    final coords = _coordsFromLocationField(loc);
    return ParamedicoIncidentSummary(
      id: j['id'] as String,
      generatedTitle: j['generated_title'] as String? ?? '—',
      emergencyType: j['emergency_type'] as String? ?? 'otro',
      createdAt: (j['created_at'] as String?) != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
      createdBy: j['created_by'] as String? ?? '',
      description: j['description'] as String?,
      photoPaths: _stringListFromDynamic(j['photo_local_paths']),
      latitude: coords?.$1,
      longitude: coords?.$2,
    );
  }
}

List<String> _stringListFromDynamic(dynamic raw) {
  if (raw is List) {
    return raw.whereType<String>().where((e) => e.trim().isNotEmpty).toList();
  }
  return const [];
}

(double, double)? _coordsFromEwkbHex(String hex) {
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

(double, double)? _registrationCoordsFromDemographics(dynamic demo) {
  if (demo is! Map<String, dynamic>) return null;
  final lat = demo['registration_lat'];
  final lng = demo['registration_lng'];
  if (lat is num && lng is num) return (lat.toDouble(), lng.toDouble());
  return null;
}

/// Coordenadas en escena del incidente (triage), no GPS de traslado lejano
(double, double)? _sceneCoordsForIncident({
  required (double, double)? fromLocation,
  required (double, double)? fromRegistration,
  required double incidentLat,
  required double incidentLng,
}) {
  const distance = Distance();
  final center = LatLng(incidentLat, incidentLng);
  final maxSceneM =
      MapIncidentCoverageService.maxPatientDistanceFromIncidentMeters;

  double? metersFromIncident((double, double)? coords) {
    if (coords == null) return null;
    return distance(center, LatLng(coords.$1, coords.$2));
  }

  final dLoc = metersFromIncident(fromLocation);
  final dReg = metersFromIncident(fromRegistration);
  final locInScene = dLoc != null && dLoc <= maxSceneM;
  final regInScene = dReg != null && dReg <= maxSceneM;

  if (regInScene && locInScene) return fromRegistration;
  if (regInScene) return fromRegistration;
  if (locInScene) return fromLocation;

  return null;
}

(double, double)? _patientCoordsFromRow(
  Map<String, dynamic> j, {
  double? incidentLat,
  double? incidentLng,
}) {
  final fromLocation = _coordsFromLocationField(j['location']);
  final fromRegistration = _registrationCoordsFromDemographics(
    j['demographics'],
  );

  if (incidentLat != null && incidentLng != null) {
    return _sceneCoordsForIncident(
      fromLocation: fromLocation,
      fromRegistration: fromRegistration,
      incidentLat: incidentLat,
      incidentLng: incidentLng,
    );
  }

  return fromRegistration ?? fromLocation;
}

(double, double)? _coordsFromLocationField(dynamic location) {
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

/// Conteos de pacientes por color de triage para tarjetas de incidente
class IncidentPatientTriageCounts {
  IncidentPatientTriageCounts({
    required this.red,
    required this.yellow,
    required this.green,
    required this.black,
    required this.total,
  });

  final int red;
  final int yellow;
  final int green;
  final int black;
  final int total;
}

/// Fila de paciente en detalle de incidente
class ParamedicoPatientRow {
  ParamedicoPatientRow({
    required this.id,
    required this.displayName,
    required this.triageColor,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String triageColor;
  final String status;
  final DateTime? createdAt;

  factory ParamedicoPatientRow.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final name = j['display_name'] as String?;
    final notes = j['descriptive_notes'] as String?;
    final folio = j['regulation_folio'] as String?;
    final display = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (folio != null && folio.isNotEmpty)
        ? folio
        : (notes != null && notes.trim().isNotEmpty)
        ? notes.trim().split('\n').first
        : 'Paciente ${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id}';

    return ParamedicoPatientRow(
      id: id,
      displayName: display,
      triageColor: j['triage_color'] as String? ?? 'amarillo',
      status: j['status'] as String? ?? 'registrado',
      createdAt: (j['created_at'] as String?) != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
    );
  }
}

/// Paciente con campos extra para pantalla de detalle / traslado
class ParamedicoPatientDetail {
  ParamedicoPatientDetail({
    required this.id,
    required this.displayName,
    required this.triageColor,
    required this.status,
    required this.createdAt,
    required this.incidentId,
    required this.createdBy,
    required this.demographics,
    this.regulationFolio,
    this.hospitalId,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String displayName;
  final String triageColor;
  final String status;
  final DateTime? createdAt;
  final String incidentId;
  final String createdBy;
  final Map<String, dynamic> demographics;
  final String? regulationFolio;
  final String? hospitalId;
  final double? latitude;
  final double? longitude;

  factory ParamedicoPatientDetail.fromJson(Map<String, dynamic> j) {
    final loc = j['location'];
    final coords = _coordsFromLocationField(loc);
    final demo = j['demographics'];
    Map<String, dynamic> d = {};
    if (demo is Map<String, dynamic>) {
      d = Map<String, dynamic>.from(demo);
    }
    final id = j['id'] as String;
    final name = j['display_name'] as String?;
    final folio = j['regulation_folio'] as String?;
    final notes = j['descriptive_notes'] as String?;
    final display = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (folio != null && folio.isNotEmpty)
        ? folio
        : (notes != null && notes.trim().isNotEmpty)
        ? notes.trim().split('\n').first
        : 'Paciente ${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id}';

    return ParamedicoPatientDetail(
      id: id,
      displayName: display,
      triageColor: j['triage_color'] as String? ?? 'amarillo',
      status: j['status'] as String? ?? 'registrado',
      createdAt: (j['created_at'] as String?) != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
      incidentId: j['incident_id'] as String? ?? '',
      createdBy: j['created_by'] as String? ?? '',
      demographics: d,
      regulationFolio: j['regulation_folio'] as String?,
      hospitalId: j['hospital_id'] as String?,
      latitude: coords?.$1,
      longitude: coords?.$2,
    );
  }
}

class HospitalRow {
  HospitalRow({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  factory HospitalRow.fromJson(Map<String, dynamic> j) {
    final loc = j['location'];
    final c = _coordsFromLocationField(loc);
    return HospitalRow(
      id: j['id'] as String,
      name: j['name'] as String? ?? 'Hospital',
      address: j['address'] as String?,
      latitude: c?.$1,
      longitude: c?.$2,
    );
  }
}

/// Contrato de datos paramédico ↔ Supabase (columnas `patients`, Storage `patient_photos`, RPC incidentes)
/// Ver migración `20260513120000_paramedico_patient_demographics.sql`
class ParamedicoIncidentsRepository {
  ParamedicoIncidentsRepository({SupabaseClient? client})
    : _client =
          client ??
          (SupabaseEnv.isConfigured ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  SupabaseClient get _c {
    final x = _client;
    if (x == null) throw Exception('El servicio no se encuentra configurado en este momento');
    return x;
  }

  Future<List<ParamedicoIncidentSummary>> listOpenIncidents() async {
    final rows = await _c
        .from('incidents')
        .select(
          'id, generated_title, emergency_type, description, photo_local_paths, '
          'created_at, status, created_by, location',
        )
        .eq('is_deleted', false)
        .eq('status', 'activo')
        .order('created_at', ascending: false);

    final list = rows as List<dynamic>;
    return list
        .map(
          (e) => ParamedicoIncidentSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ParamedicoIncidentSummary?> getIncident(String incidentId) async {
    final row = await _c
        .from('incidents')
        .select(
          'id, generated_title, emergency_type, description, photo_local_paths, '
          'created_at, status, created_by, location',
        )
        .eq('id', incidentId)
        .eq('is_deleted', false)
        .maybeSingle();
    if (row == null) return null;
    return ParamedicoIncidentSummary.fromJson(Map<String, dynamic>.from(row));
  }

  /// Pacientes activos del incidente (para numeración al registrar uno nuevo)
  Future<int> countPatientsForIncident(String incidentId) async {
    final rows = await _c
        .from('patients')
        .select('id')
        .eq('incident_id', incidentId)
        .eq('is_deleted', false);
    return (rows as List<dynamic>).length;
  }

  Future<List<ParamedicoPatientRow>> listPatientsForIncident(
    String incidentId,
  ) async {
    final rows = await _c
        .from('patients')
        .select(
          'id, display_name, triage_color, status, created_at, regulation_folio, descriptive_notes',
        )
        .eq('incident_id', incidentId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);
    final list = rows as List<dynamic>;
    return list
        .map((e) => ParamedicoPatientRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Una sola consulta: triage_color de pacientes para los incidentes dados
  Future<Map<String, IncidentPatientTriageCounts>>
  patientTriageCountsByIncident(Iterable<String> incidentIds) async {
    final ids = incidentIds.toList();
    if (ids.isEmpty) return {};
    final rows = await _c
        .from('patients')
        .select('incident_id, triage_color')
        .inFilter('incident_id', ids)
        .eq('is_deleted', false);

    final agg = <String, _TriageAgg>{};
    for (final id in ids) {
      agg[id] = _TriageAgg();
    }
    for (final raw in rows as List<dynamic>) {
      final j = raw as Map<String, dynamic>;
      final iid = j['incident_id'] as String?;
      final color = j['triage_color'] as String? ?? 'amarillo';
      if (iid == null) continue;
      final a = agg[iid];
      if (a == null) continue;
      a.total++;
      switch (color) {
        case 'rojo':
          a.red++;
          break;
        case 'amarillo':
        case 'naranja':
          a.yellow++;
          break;
        case 'verde':
        case 'azul':
          a.green++;
          break;
        case 'negro':
          a.black++;
          break;
        default:
          a.yellow++;
          break;
      }
    }
    return agg.map(
      (k, v) => MapEntry(
        k,
        IncidentPatientTriageCounts(
          red: v.red,
          yellow: v.yellow,
          green: v.green,
          black: v.black,
          total: v.total,
        ),
      ),
    );
  }

  /// Ubicaciones de pacientes con coordenadas para el mapa interactivo
  Future<List<MapPatientPin>> listMapPatientPinsForIncidents(
    Iterable<String> incidentIds, {
    Map<String, LatLng> incidentCentersById = const {},
  }) async {
    final ids = incidentIds.toList();
    if (ids.isEmpty) return [];
    final rows = await _c
        .from('patients')
        .select('id, incident_id, triage_color, location, demographics')
        .inFilter('incident_id', ids)
        .eq('is_deleted', false);

    final pinsByIncident = <String, List<MapPatientPin>>{};
    for (final raw in rows as List<dynamic>) {
      final j = raw as Map<String, dynamic>;
      final incidentId = j['incident_id'] as String? ?? '';
      final incidentCenter = incidentCentersById[incidentId];
      final coords =
          _patientCoordsFromRow(
            j,
            incidentLat: incidentCenter?.latitude,
            incidentLng: incidentCenter?.longitude,
          ) ??
          (incidentCenter != null
              ? (incidentCenter.latitude, incidentCenter.longitude)
              : null);
      if (coords == null) continue;
      pinsByIncident
          .putIfAbsent(incidentId, () => [])
          .add(
            MapPatientPin(
              id: j['id'] as String,
              incidentId: j['incident_id'] as String? ?? '',
              latitude: coords.$1,
              longitude: coords.$2,
              triageColor: j['triage_color'] as String? ?? 'amarillo',
            ),
          );
    }

    final pins = <MapPatientPin>[];
    for (final entry in pinsByIncident.entries) {
      final center = incidentCentersById[entry.key];
      pins.addAll(_spreadOverlappingPins(entry.value, center));
    }
    return pins;
  }

  List<MapPatientPin> _spreadOverlappingPins(
    List<MapPatientPin> pins,
    LatLng? incidentCenter,
  ) {
    if (pins.length <= 1) return pins;

    final groups = <String, List<MapPatientPin>>{};
    for (final pin in pins) {
      final key =
          '${pin.latitude.toStringAsFixed(6)},${pin.longitude.toStringAsFixed(6)}';
      groups.putIfAbsent(key, () => []).add(pin);
    }

    final distance = const Distance();
    final spread = <MapPatientPin>[];
    for (final group in groups.values) {
      if (group.length == 1) {
        spread.add(group.first);
        continue;
      }

      final anchor = LatLng(group.first.latitude, group.first.longitude);
      final baseRadius = (10 + group.length * 1.8).clamp(12, 28).toDouble();
      var radius = baseRadius;
      if (incidentCenter != null) {
        final anchorMeters = distance(incidentCenter, anchor);
        final remaining =
            MapIncidentCoverageService.maxPatientDistanceFromIncidentMeters -
            anchorMeters -
            2;
        radius = min(baseRadius, max(4.0, remaining));
      }
      for (var i = 0; i < group.length; i++) {
        final pin = group[i];
        final angle = (360 / group.length) * i + (_stableAngle(pin.id) % 24);
        final point = distance.offset(anchor, radius, angle);
        spread.add(
          MapPatientPin(
            id: pin.id,
            incidentId: pin.incidentId,
            latitude: point.latitude,
            longitude: point.longitude,
            triageColor: pin.triageColor,
          ),
        );
      }
    }

    if (incidentCenter == null) return spread;

    return spread.where((pin) {
      final meters = distance(
        incidentCenter,
        LatLng(pin.latitude, pin.longitude),
      );
      return meters <=
          MapIncidentCoverageService.maxPatientDistanceFromIncidentMeters;
    }).toList();
  }

  int _stableAngle(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash % 360;
  }

  HomeDashboardStats dashboardStats({
    required List<ParamedicoIncidentSummary> openIncidents,
    required Map<String, IncidentPatientTriageCounts> countsByIncident,
  }) {
    var totalPatients = 0;
    var red = 0;
    var yellow = 0;
    var green = 0;
    for (final inc in openIncidents) {
      final c = countsByIncident[inc.id];
      if (c == null) continue;
      totalPatients += c.total;
      red += c.red;
      yellow += c.yellow;
      green += c.green;
    }
    return HomeDashboardStats(
      totalActiveIncidents: openIncidents.length,
      totalPatients: totalPatients,
      redCount: red,
      yellowCount: yellow,
      greenCount: green,
    );
  }

  Future<String> createIncident({
    required String title,
    required String emergencyType,
    double lng = -117.00371,
    double lat = 32.5027,
  }) async {
    final res = await _c.rpc(
      'create_incident_for_paramedic',
      params: {
        'p_title': title,
        'p_emergency_type': emergencyType,
        'p_lng': lng,
        'p_lat': lat,
      },
    );
    final s = res.toString().trim();
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  Future<void> updateIncidentDescription({
    required String incidentId,
    String? description,
  }) async {
    await _c
        .from('incidents')
        .update({'description': description})
        .eq('id', incidentId);
  }

  Future<void> updateIncidentTitle({
    required String incidentId,
    required String title,
  }) async {
    await _c
        .from('incidents')
        .update({'generated_title': title})
        .eq('id', incidentId);
  }

  Future<void> updateIncidentPhotoPaths({
    required String incidentId,
    required List<String> photoPaths,
  }) async {
    await _c
        .from('incidents')
        .update({'photo_local_paths': photoPaths})
        .eq('id', incidentId);
  }

  /// Actualiza `incidents.location` (geography Point). GeoJSON; si el API lo rechaza, intenta EWKT
  Future<void> updateIncidentLocation({
    required String incidentId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _c
          .from('incidents')
          .update({
            'location': {
              'type': 'Point',
              'coordinates': [lng, lat],
            },
          })
          .eq('id', incidentId);
    } catch (_) {
      await _c
          .from('incidents')
          .update({'location': 'SRID=4326;POINT($lng $lat)'})
          .eq('id', incidentId);
    }
  }

  Future<void> closeIncident(String incidentId) async {
    await _c
        .from('incidents')
        .update({
          'status': 'cerrado',
          'closed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', incidentId);
  }

  /// Crea un paciente vinculado al incidente y un código de consulta de 6 caracteres
  Future<String> registerPatientWithConsultationCode({
    required String incidentId,
    required String triageColor,
  }) async {
    final uid = const Uuid().v4();

    final uidAuth = _c.auth.currentUser?.id;
    if (uidAuth == null) throw Exception('La sesión no es válida o ha expirado');

    final inserted = await _c
        .from('patients')
        .insert({
          'sync_client_id': uid,
          'incident_id': incidentId,
          'triage_color': triageColor,
          'status': 'registrado',
          'created_by': uidAuth,
        })
        .select('id')
        .single();

    final patientId = inserted['id'] as String;

    final code = await _insertUniqueConsultationCode(
      patientId: patientId,
      createdBy: uidAuth,
    );
    return code;
  }

  /// Registro completo (display_name + demographics + ubicación del paciente + código de consulta)
  Future<String> registerPatientFull({
    required String incidentId,
    required String triageColor,
    required String displayName,
    required Map<String, dynamic> demographics,
    required double locationLat,
    required double locationLng,
  }) async {
    final uid = const Uuid().v4();
    final uidAuth = _c.auth.currentUser?.id;
    if (uidAuth == null) throw Exception('La sesión no es válida o ha expirado');

    final demo = Map<String, dynamic>.from(demographics)
      ..['registration_lat'] = locationLat
      ..['registration_lng'] = locationLng;

    final insertRow = <String, dynamic>{
      'sync_client_id': uid,
      'incident_id': incidentId,
      'triage_color': triageColor,
      'status': 'registrado',
      'created_by': uidAuth,
      'display_name': displayName.trim().isEmpty ? null : displayName.trim(),
      'demographics': demo,
    };

    final inserted = Map<String, dynamic>.from(
      await _c.from('patients').insert(insertRow).select('id').single(),
    );

    final patientId = inserted['id'] as String;

    await updatePatientRecord(
      patientId: patientId,
      locationLat: locationLat,
      locationLng: locationLng,
    );

    return _insertUniqueConsultationCode(
      patientId: patientId,
      createdBy: uidAuth,
    );
  }

  Future<void> updatePatientRecord({
    required String patientId,
    String? displayName,
    String? triageColor,
    Map<String, dynamic>? demographics,
    String? status,
    String? hospitalId,
    String? regulationFolio,
    String? ambulanceUnitId,
    double? locationLat,
    double? locationLng,
  }) async {
    final patch = <String, dynamic>{};
    if (displayName != null) patch['display_name'] = displayName;
    if (triageColor != null) patch['triage_color'] = triageColor;
    if (demographics != null) patch['demographics'] = demographics;
    if (status != null) patch['status'] = status;
    if (hospitalId != null) patch['hospital_id'] = hospitalId;
    if (regulationFolio != null) patch['regulation_folio'] = regulationFolio;
    if (ambulanceUnitId != null) patch['ambulance_unit_id'] = ambulanceUnitId;
    if (patch.isNotEmpty) {
      await _c.from('patients').update(patch).eq('id', patientId);
    }

    if (locationLat != null && locationLng != null) {
      await updatePatientLocation(
        patientId: patientId,
        lat: locationLat,
        lng: locationLng,
      );
    }
  }

  Future<void> updatePatientLocation({
    required String patientId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _c.rpc(
        'paramedico_update_patient_location',
        params: {'p_patient_id': patientId, 'p_lat': lat, 'p_lng': lng},
      );
    } catch (e) {
      throw Exception('No se pudo guardar la ubicación del paciente: $e');
    }
  }

  /// Fusiona [demographicsExtras] con el JSON actual del paciente y actualiza estado / hospital / folio
  ///
  /// El trigger `enforce_patient_status_transition` solo permite saltos de +1; si el estado actual es
  /// `registrado` y [newStatus] es `trasladando`, primero se persiste `en_espera` y luego `trasladando`
  Future<void> applyPatientTransfer({
    required String patientId,
    required String newStatus,
    String? hospitalId,
    String? regulationFolio,
    Map<String, dynamic>? demographicsExtras,
    double? patientLocationLat,
    double? patientLocationLng,
  }) async {
    final cur = await getPatientDetail(patientId);
    if (cur == null) throw Exception('Paciente no encontrado.');
    final merged = Map<String, dynamic>.from(cur.demographics);
    if (demographicsExtras != null) merged.addAll(demographicsExtras);
    final ambulanceUnitId = newStatus == 'trasladando'
        ? await currentAmbulanceUnitId()
        : null;
    if (newStatus == 'trasladando' &&
        (ambulanceUnitId == null || ambulanceUnitId.isEmpty)) {
      throw Exception(
        'Registra el código de tu unidad desde perfil antes de enviar el traslado.',
      );
    }

    if (newStatus == 'trasladando' && cur.status == 'registrado') {
      await updatePatientRecord(patientId: patientId, status: 'en_espera');
    }

    await updatePatientRecord(
      patientId: patientId,
      status: newStatus,
      hospitalId: hospitalId,
      regulationFolio: regulationFolio,
      ambulanceUnitId: ambulanceUnitId,
      demographics: merged,
      locationLat: patientLocationLat,
      locationLng: patientLocationLng,
    );
  }

  Future<ParamedicoPatientRow?> getPatient(String patientId) async {
    final row = await _c
        .from('patients')
        .select(
          'id, display_name, triage_color, status, created_at, regulation_folio, descriptive_notes, demographics, incident_id',
        )
        .eq('id', patientId)
        .eq('is_deleted', false)
        .maybeSingle();
    if (row == null) return null;
    return ParamedicoPatientRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<ParamedicoPatientDetail?> getPatientDetail(String patientId) async {
    final row = await _c
        .from('patients')
        .select(
          'id, display_name, triage_color, status, created_at, regulation_folio, '
          'descriptive_notes, demographics, incident_id, hospital_id, location, created_by',
        )
        .eq('id', patientId)
        .eq('is_deleted', false)
        .maybeSingle();
    if (row == null) return null;
    return ParamedicoPatientDetail.fromJson(Map<String, dynamic>.from(row));
  }

  /// Código activo (no revocado) más reciente del paciente, si existe
  Future<String?> getActiveConsultationCode(String patientId) async {
    final rows = await _c
        .from('consultation_codes')
        .select('code, revoked_at, created_at')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    final list = rows as List<dynamic>;
    for (final raw in list) {
      final m = raw as Map<String, dynamic>;
      if (m['revoked_at'] != null) continue;
      final code = m['code'] as String?;
      if (code != null && code.trim().isNotEmpty) return code.trim();
    }
    return null;
  }

  /// Devuelve el código existente o crea uno nuevo en `consultation_codes`
  Future<String> ensureConsultationCode(String patientId) async {
    final existing = await getActiveConsultationCode(patientId);
    if (existing != null) return existing;
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw Exception('Sesión inválida.');
    return _insertUniqueConsultationCode(patientId: patientId, createdBy: uid);
  }

  Future<List<HospitalRow>> listActiveHospitals() async {
    final rows = await _c
        .from('hospitals')
        .select('id, name, address, location')
        .eq('is_deleted', false)
        .eq('is_active', true)
        .order('name');
    final list = rows as List<dynamic>;
    return list
        .map((e) => HospitalRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HospitalRow?> getHospitalById(String hospitalId) async {
    final row = await _c
        .from('hospitals')
        .select('id, name, address, location')
        .eq('id', hospitalId)
        .eq('is_deleted', false)
        .maybeSingle();
    if (row == null) return null;
    return HospitalRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<String?> getProfileFullName(String profileId) async {
    final row = await _c
        .from('profiles')
        .select('full_name')
        .eq('id', profileId)
        .maybeSingle();
    if (row == null) return null;
    final n = row['full_name'] as String?;
    if (n == null || n.trim().isEmpty) return null;
    return n.trim();
  }

  Future<String?> currentAmbulanceUnitId() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw Exception('Sesión inválida.');
    final row = await _c
        .from('profiles')
        .select('ambulance_unit_id')
        .eq('id', uid)
        .maybeSingle();
    return row?['ambulance_unit_id']?.toString();
  }

  Future<String?> currentAmbulanceUnitCode() async {
    final unitId = await currentAmbulanceUnitId();
    if (unitId == null || unitId.isEmpty) return null;
    final row = await _c
        .from('ambulancias_unidades')
        .select('numero_economico')
        .eq('id', unitId)
        .eq('is_deleted', false)
        .maybeSingle();
    final code = (row?['numero_economico'] as String?)?.trim();
    return code == null || code.isEmpty ? null : code;
  }

  Future<String> setCurrentAmbulanceUnitCode(String rawCode) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw Exception('Sesión inválida.');
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) throw Exception('Escribe el código de tu unidad.');

    final unitId = await _ensureAmbulanceUnit(code);
    await _c
        .from('profiles')
        .update({'ambulance_unit_id': unitId})
        .eq('id', uid);
    return code;
  }

  Future<String> _ensureAmbulanceUnit(String code) async {
    final existing = await _c
        .from('ambulancias_unidades')
        .select('id, is_deleted')
        .eq('numero_economico', code)
        .maybeSingle();
    final existingId = existing?['id'];
    if (existingId != null) {
      if (existing?['is_deleted'] == true) {
        await _c
            .from('ambulancias_unidades')
            .update({'is_deleted': false, 'is_active': true})
            .eq('id', existingId);
      }
      return existingId.toString();
    }

    try {
      final inserted = await _c
          .from('ambulancias_unidades')
          .insert({'numero_economico': code})
          .select('id')
          .single();
      return inserted['id'].toString();
    } on PostgrestException catch (e) {
      if (!_isConsultationCodeCollision(e)) rethrow;
      final row = await _c
          .from('ambulancias_unidades')
          .select('id')
          .eq('numero_economico', code)
          .single();
      return row['id'].toString();
    }
  }

  Future<List<ParamedicoPatientRow>> listRecentPatientsForCurrentUser({
    int limit = 40,
  }) async {
    final uidAuth = _c.auth.currentUser?.id;
    if (uidAuth == null) throw Exception('Sesión inválida.');
    final rows = await _c
        .from('patients')
        .select(
          'id, display_name, triage_color, status, created_at, regulation_folio, descriptive_notes',
        )
        .eq('created_by', uidAuth)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);
    final list = rows as List<dynamic>;
    return list
        .map((e) => ParamedicoPatientRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> _insertUniqueConsultationCode({
    required String patientId,
    required String createdBy,
  }) async {
    final rnd = Random.secure();
    for (var attempt = 0; attempt < 12; attempt++) {
      final code = _randomConsultationCode(rnd);
      if (await _consultationCodeExists(code)) continue;
      try {
        await _c.from('consultation_codes').insert({
          'patient_id': patientId,
          'code': code,
          'created_by': createdBy,
        });
        return code;
      } on PostgrestException catch (e) {
        if (!_isConsultationCodeCollision(e)) rethrow;
        continue;
      }
    }
    throw Exception('No fue posible generar un código único.');
  }

  String _randomConsultationCode(Random rnd) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buf = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buf.write(alphabet[rnd.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }

  Future<bool> _consultationCodeExists(String code) async {
    final rows = await _c
        .from('consultation_codes')
        .select('id')
        .eq('code', code)
        .limit(1);
    return (rows as List<dynamic>).isNotEmpty;
  }

  bool _isConsultationCodeCollision(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '23505' ||
        message.contains('duplicate key') ||
        message.contains('unique');
  }
}

class _TriageAgg {
  int red = 0;
  int yellow = 0;
  int green = 0;
  int black = 0;
  int total = 0;
}

/// Totales agregados para [Minidash] (home paramédico)
class HomeDashboardStats {
  HomeDashboardStats({
    required this.totalActiveIncidents,
    required this.totalPatients,
    required this.redCount,
    required this.yellowCount,
    required this.greenCount,
  });

  final int totalActiveIncidents;
  final int totalPatients;
  final int redCount;
  final int yellowCount;
  final int greenCount;
}
