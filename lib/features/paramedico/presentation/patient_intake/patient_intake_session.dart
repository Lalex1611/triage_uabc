import 'dart:async';

import 'package:sistema_triage/core/geo/nominatim_reverse_geocode.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_display_name_formatter.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

typedef GeoPoint = ({double lat, double lng});

/// Paciente recién guardado desde un panel de registro
class RegisteredPatient {
  const RegisteredPatient({
    required this.id,
    required this.number,
    required this.level,
  });

  final String id;
  final int number;
  final TriageLevel level;

  String get folio => IncidentPresentationFormatters.shortPatientId(id);
}

/// Registro de pacientes de un incidente desde los paneles de B11
///
/// [prepare] consulta una sola vez el incidente y el nombre del lugar, para que
/// registrar varios pacientes seguidos (Emergencias) no repita esas consultas.
/// Cada paciente toma la ubicación del dispositivo y, si no está disponible, la
/// del incidente.
class PatientIntakeSession {
  PatientIntakeSession({
    required this.incidentId,
    ParamedicoIncidentsRepository? repository,
    Future<GeoPoint?> Function()? currentPosition,
    Future<String?> Function(double lat, double lng)? placeLabel,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       _currentPosition =
           currentPosition ?? IncidentLocationService.getCurrentPosition,
       _placeLabel = placeLabel ?? NominatimReverseGeocode.shortPlaceLabel;

  final String incidentId;
  final ParamedicoIncidentsRepository _repo;
  final Future<GeoPoint?> Function() _currentPosition;
  final Future<String?> Function(double lat, double lng) _placeLabel;

  static const _gpsTimeout = Duration(seconds: 10);

  /// Número que tendrá el siguiente paciente del incidente
  int nextNumber = 1;
  GeoPoint? _incidentPoint;
  String? _placeKey;
  bool _prepared = false;

  /// Si ya se leyeron el incidente y el número del siguiente paciente
  bool get isPrepared => _prepared;

  String get incidentFolio =>
      IncidentPresentationFormatters.shortIncidentId(incidentId);

  /// Pacientes que ya tiene el incidente
  int get registeredCount => nextNumber - 1;

  Future<void> prepare() async {
    if (_prepared) return;
    final incident = await _repo.getIncident(incidentId);
    if (incident == null) throw Exception('Incidente no encontrado.');
    nextNumber = await _repo.countPatientsForIncident(incidentId) + 1;
    final lat = incident.latitude;
    final lng = incident.longitude;
    if (lat != null && lng != null) {
      _incidentPoint = (lat: lat, lng: lng);
      _placeKey = await _placeLabel(lat, lng) ?? _coords((lat: lat, lng: lng));
    }
    _prepared = true;
  }

  Future<RegisteredPatient> register({
    required TriageLevel level,
    String? name,
    List<String> photos = const [],
    StartTriageTabOption mode = StartTriageTabOption.asignacionRapida,
  }) async {
    await prepare();
    final point = await _devicePoint() ?? _incidentPoint;
    if (point == null) {
      throw Exception(
        'No se pudo obtener la ubicación. Activa el GPS e inténtalo de nuevo.',
      );
    }
    final number = nextNumber;
    final custom = name?.trim();
    final saved = await _repo.registerPatientFull(
      incidentId: incidentId,
      triageColor: level.dbValue,
      displayName: custom != null && custom.isNotEmpty
          ? custom
          : PatientDisplayNameFormatter.formatAuto(
              patientNumber: number,
              atLocal: DateTime.now(),
              locationKey: _placeKey ?? _coords(point),
            ),
      demographics: {
        'photo_local_paths': List<String>.from(photos),
        'registered_from_start': true,
        'start_triage_mode': mode.name,
      },
      locationLat: point.lat,
      locationLng: point.lng,
    );
    nextNumber++;
    return RegisteredPatient(id: saved.patientId, number: number, level: level);
  }

  /// Sin permiso, sin GPS o si tarda demasiado se usa la ubicación del incidente
  Future<GeoPoint?> _devicePoint() async {
    try {
      return await _currentPosition().timeout(_gpsTimeout);
    } catch (_) {
      return null;
    }
  }

  static String _coords(GeoPoint p) =>
      '${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}';
}
