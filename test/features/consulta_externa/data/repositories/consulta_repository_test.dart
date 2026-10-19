import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:postgrest/postgrest.dart';
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
              'found': true,
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

  for (final error in ['not_found', 'invalid_code']) {
    test('HTTP 200 con $error no devuelve un paciente en espera', () async {
      await http.runWithClient(
        () => expectLater(
          ConsultaRepository().lookupByCode('AB3K7X'),
          throwsA(
            isA<PostgrestException>().having(
              (error) => error.message,
              'mensaje',
              'not_found',
            ),
          ),
        ),
        () => MockClient(
          (_) async =>
              http.Response(jsonEncode({'found': false, 'error': error}), 200),
        ),
      );
    });
  }

  test('Distingue el límite de consultas de un código inexistente', () async {
    await http.runWithClient(
      () => expectLater(
        ConsultaRepository().lookupByCode('AB3K7X'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'mensaje',
            contains('cinco minutos'),
          ),
        ),
      ),
      () => MockClient(
        (_) async =>
            http.Response('{"found":false,"error":"rate_limited"}', 200),
      ),
    );
  });

  for (final body in [
    {},
    {'patient_status': 'en_espera'},
    {'found': 'true', 'patient_status': 'en_espera'},
    {'found': true},
    {'found': true, 'patient_status': 'estado_desconocido'},
    {'found': true, 'error': 'not_found', 'patient_status': 'en_espera'},
    {'found': false, 'error': 'fallo_desconocido'},
  ]) {
    test('Rechaza una respuesta incompleta o contradictoria: $body', () async {
      await http.runWithClient(
        () => expectLater(
          ConsultaRepository().lookupByCode('AB3K7X'),
          throwsA(isA<Exception>()),
        ),
        () => MockClient((_) async => http.Response(jsonEncode(body), 200)),
      );
    });
  }

  for (final entry in {
    'en_espera': ConsultaStatus.enEspera,
    'trasladando': ConsultaStatus.trasladando,
    'recibido': ConsultaStatus.recibido,
    'alta_medica': ConsultaStatus.alta,
  }.entries) {
    test('Acepta found true con el estado ${entry.key}', () async {
      await http.runWithClient(
        () async {
          final result = await ConsultaRepository().lookupByCode('AB3K7X');
          expect(result.status, entry.value);
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({'found': true, 'patient_status': entry.key}),
            200,
          ),
        ),
      );
    });
  }
}
