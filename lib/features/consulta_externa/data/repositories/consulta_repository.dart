import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:postgrest/postgrest.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/consulta_externa/data/models/consulta_rpc_row.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';

/// Permite realizar la consulta pública del estado del paciente mediante su código
class ConsultaRepository {
  ConsultaRepository();

  Future<ConsultaLookupResult> lookupByCode(String rawCode) async {
    if (!SupabaseEnv.isConfigured) {
      throw Exception('El servicio no se encuentra configurado en este momento');
    }

    final normalized =
        rawCode.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (normalized.length < 4 || normalized.length > 64) {
      throw Exception('El código ingresado no tiene un formato válido');
    }

    final base = SupabaseEnv.projectUrl;
    final key = SupabaseEnv.anonKey;
    if (base.isEmpty || key.isEmpty) {
      throw Exception('Ocurrió un error con la configuración del servicio');
    }

    final uri = Uri.parse('$base/rest/v1/rpc/get_patient_status_by_code');

    final http.Response resp;
    try {
      resp = await http
          .post(
            uri,
            headers: {
              'apikey': key,
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'p_code': normalized}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Ocurrió un error al intentar conectarse con el servidor, por favor verifica tu conexión a internet');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is! Map) {
          throw Exception('El servidor respondió de una forma inesperada');
        }
        final map = Map<String, dynamic>.from(decoded);
        final row = ConsultaRpcRow.fromJson(map);
        final status = _parseLifecycle(row.patientStatusRaw);

        return ConsultaLookupResult(
          status: status,
          hospitalName: row.hospitalName,
          hospitalAddress: row.hospitalAddress,
          hospitalPhone: row.hospitalPhone,
        );
      } catch (e) {
        rethrow;
      }
    }

    return _throwPostgrestOrDetail(uri, resp);
  }

  Never _throwPostgrestOrDetail(Uri uri, http.Response resp) {
    Map<String, dynamic>? j;
    try {
      j = jsonDecode(resp.body) as Map<String, dynamic>?;
    } catch (_) {}

    final msg = j?['message'] as String? ?? resp.body;
    final code = j?['code'] as String?;

    if (msg.contains('not_found') ||
        (msg.toLowerCase().contains('not found')) ||
        code == 'P0001') {
      throw PostgrestException(message: msg, code: code);
    }

    throw Exception('No pudimos procesar la solicitud en este momento (Código: ${resp.statusCode})');
  }

  ConsultaStatus _parseLifecycle(String? raw) {
    switch (raw) {
      case 'registrado':
        return ConsultaStatus.registrado;
      case 'en_espera':
        return ConsultaStatus.enEspera;
      case 'trasladando':
        return ConsultaStatus.trasladando;
      case 'recibido':
        return ConsultaStatus.recibido;
      case 'alta_medica':
        return ConsultaStatus.alta;
      default:
        return ConsultaStatus.registrado;
    }
  }
}
