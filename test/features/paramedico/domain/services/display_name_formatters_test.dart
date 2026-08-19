import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_title_formatter.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_display_name_formatter.dart';

void main() {
  final at = DateTime(2026, 3, 18, 14, 32);

  test('incident auto title uses dash between time and location', () {
    expect(
      IncidentTitleFormatter.formatAuto(
        atLocal: at,
        locationKey: 'Boulevard 2000',
      ),
      '18-marzo-2026 14:32-Boulevard 2000',
    );
  });

  test('patient auto name prefixes Paciente Numero and reuses incident suffix', () {
    expect(
      PatientDisplayNameFormatter.formatAuto(
        patientNumber: 3,
        atLocal: at,
        locationKey: 'Boulevard 2000',
      ),
      'Paciente Numero 3 - 18-marzo-2026 14:32-Boulevard 2000',
    );
  });

  test('resolveDisplayName keeps custom name when provided', () async {
    final name = await PatientDisplayNameFormatter.resolveDisplayName(
      customName: 'Alias manual',
      patientNumber: 1,
      atLocal: at,
      lat: 0,
      lng: 0,
    );
    expect(name, 'Alias manual');
  });
}
