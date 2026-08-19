import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';

void main() {
  group('ParamedicoCatalogMappers.statusFromDb', () {
    test('keeps en_espera as its own lifecycle status', () {
      expect(
        ParamedicoCatalogMappers.statusFromDb('en_espera'),
        PatientStatus.enEspera,
      );
    });
  });
}
