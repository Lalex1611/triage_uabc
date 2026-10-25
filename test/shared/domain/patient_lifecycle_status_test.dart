import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/domain/patient_lifecycle_status.dart';

void main() {
  test(
    'dbValue coincide con public.patient_lifecycle_status y fromDb regresa',
    () {
      expect(PatientLifecycleStatus.values.map((s) => s.dbValue), [
        'en_espera',
        'trasladando',
        'recibido',
        'alta_medica',
      ]);
      for (final status in PatientLifecycleStatus.values) {
        expect(PatientLifecycleStatus.fromDb(status.dbValue), status);
      }
    },
  );

  test('fromDb devuelve null para valores desconocidos o nulos', () {
    expect(PatientLifecycleStatus.fromDb(null), isNull);
    expect(PatientLifecycleStatus.fromDb(''), isNull);
    expect(PatientLifecycleStatus.fromDb('EN_ESPERA'), isNull);
    expect(PatientLifecycleStatus.fromDb('defuncion'), isNull);
  });
}
