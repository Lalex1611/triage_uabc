import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';

void main() {
  test('medico can select only received and discharged lifecycle states', () {
    final selectable = MedicoPatientStatus.values
        .where((status) => status.canBeSelectedByMedico)
        .toList();

    expect(selectable, [
      MedicoPatientStatus.recibido,
      MedicoPatientStatus.altaMedica,
    ]);
  });
}
