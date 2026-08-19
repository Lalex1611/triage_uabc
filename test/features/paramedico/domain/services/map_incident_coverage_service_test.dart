import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';

void main() {
  final center = LatLng(32.541, -116.97);

  test('ignores patients farther than scene max distance', () {
    final radius = MapIncidentCoverageService.radiusMeters(center, [
      const MapPatientPin(
        id: 'near',
        incidentId: 'i1',
        latitude: 32.5411,
        longitude: -116.9701,
        triageColor: 'rojo',
      ),
      const MapPatientPin(
        id: 'far',
        incidentId: 'i1',
        latitude: 32.57,
        longitude: -116.97,
        triageColor: 'amarillo',
      ),
    ]);

    expect(radius, lessThan(50));
    expect(radius, greaterThan(15));
  });

  test('uses minimum radius when all patients are outliers', () {
    final radius = MapIncidentCoverageService.radiusMeters(center, [
      const MapPatientPin(
        id: 'far',
        incidentId: 'i1',
        latitude: 32.6,
        longitude: -116.97,
        triageColor: 'amarillo',
      ),
    ]);

    expect(radius, MapIncidentCoverageService.minRadiusMeters);
  });
}
