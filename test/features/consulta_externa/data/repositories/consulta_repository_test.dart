import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/consulta_externa/data/repositories/consulta_repository.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';

void main() {
  setUp(() {
    SupabaseEnv.applyRuntimeFallback(
      url: 'https://consulta.example.test',
      anonKey: 'test-only-key',
    );
  });

  for (final code in ['', 'AB', 'ABCDE', 'ABCDEFG', 'AB!K7X', 'ÁB3K7X']) {
    test('Rechaza "$code" antes de consultar el servidor', () async {
      var requests = 0;
      await http.runWithClient(
        () async {
          await expectLater(
            ConsultaRepository().lookupByCode(code),
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'mensaje',
                contains('formato válido'),
              ),
            ),
          );
        },
        () => MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );
      expect(requests, 0);
    });
  }

  test(
    'Normaliza separadores y mayúsculas en el código enviado a la RPC',
    () async {
      var requests = 0;
      await http.runWithClient(
        () async {
          final result = await ConsultaRepository().lookupByCode(' ab-3 k7x\n');
          expect(result.status, ConsultaStatus.recibido);
          expect(result.hospitalName, 'Hospital de la respuesta');
        },
        () => MockClient((request) async {
          requests++;
          expect(request.method, 'POST');
          expect(request.url.path, '/rest/v1/rpc/get_patient_status_by_code');
          expect(jsonDecode(request.body), {'p_code': 'AB3K7X'});
          return http.Response(
            jsonEncode({
              'patient_status': 'recibido',
              'hospital_name': 'Hospital de la respuesta',
            }),
            200,
          );
        }),
      );
      expect(requests, 1);
    },
  );
}
