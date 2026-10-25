import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/consulta_externa/data/models/consulta_rpc_row.dart';

void main() {
  test('Interpreta la fecha real con zona horaria de la RPC', () {
    final row = ConsultaRpcRow.fromJson({
      'patient_status': 'recibido',
      'status_changed_at': '2026-10-19T05:30:00-07:00',
    });
    expect(row.statusChangedAt, DateTime.utc(2026, 10, 19, 12, 30));
  });

  for (final value in [null, '', 'fecha-invalida', 123]) {
    test('No inventa una fecha si el servidor devuelve $value', () {
      final row = ConsultaRpcRow.fromJson({
        'patient_status': 'en_espera',
        'status_changed_at': value,
      });
      expect(row.statusChangedAt, isNull);
    });
  }

  test('Mantiene compatibilidad mientras la RPC aún no devuelve la fecha', () {
    expect(
      ConsultaRpcRow.fromJson({'patient_status': 'en_espera'}).statusChangedAt,
      isNull,
    );
  });
}
