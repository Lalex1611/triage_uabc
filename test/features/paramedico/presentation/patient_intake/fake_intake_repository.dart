import 'dart:async';

import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';

/// Repositorio en memoria para probar el registro sin Supabase
class FakeIntakeRepository extends ParamedicoIncidentsRepository {
  FakeIntakeRepository({this.existing = 5, this.hasLocation = true});

  final int existing;
  final bool hasLocation;
  final registered = <Map<String, Object?>>[];
  int incidentReads = 0;
  Object? failWith;

  /// Si no es `null`, leer el incidente falla con este error (sin conexión)
  Object? incidentError;

  /// Si no es `null`, guardar espera a que se complete (red lenta)
  Completer<void>? hold;

  @override
  Future<ParamedicoIncidentSummary?> getIncident(String incidentId) async {
    incidentReads++;
    final error = incidentError;
    if (error != null) throw error;
    return ParamedicoIncidentSummary(
      id: incidentId,
      generatedTitle: 'Choque',
      emergencyType: 'accidente_vehicular',
      createdAt: null,
      createdBy: 'u1',
      latitude: hasLocation ? 32.5 : null,
      longitude: hasLocation ? -117.0 : null,
    );
  }

  @override
  Future<int> countPatientsForIncident(String incidentId) async => existing;

  @override
  Future<({String patientId, String code})> registerPatientFull({
    required String incidentId,
    required String triageColor,
    required String displayName,
    required Map<String, dynamic> demographics,
    required double locationLat,
    required double locationLng,
  }) async {
    await hold?.future;
    final error = failWith;
    if (error != null) throw error;
    registered.add({
      'triage': triageColor,
      'name': displayName,
      'lat': locationLat,
      'lng': locationLng,
      'demographics': demographics,
    });
    return (patientId: 'abcdef${registered.length}', code: 'ABC123');
  }
}
