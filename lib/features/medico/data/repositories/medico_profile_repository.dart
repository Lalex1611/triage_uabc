import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Perfil del médico (mockup 13).
/// **RPC:** `medico_profile_summary`, `medico_update_hospital_capacity`
class MedicoProfileRepository {
  MedicoProfileRepository({SupabaseClient? client})
    : _client =
          client ??
          (SupabaseEnv.isConfigured ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  SupabaseClient get _c {
    final x = _client;
    if (x == null) {
      throw Exception(
        'El servicio no se encuentra configurado en este momento',
      );
    }
    return x;
  }

  Future<MedicoProfileSummary> fetchSummary() async {
    final res = await _c.rpc('medico_profile_summary');
    return MedicoProfileSummary.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> updateCapacity({
    required int? shockBedsFree,
    required int? shockBedsTotal,
    required int? observationBedsFree,
    required int? observationBedsTotal,
    required bool? acceptingRedPatients,
    required bool? operatingRoomAvailable,
  }) async {
    await _c.rpc(
      'medico_update_hospital_capacity',
      params: {
        'p_shock_beds_free': shockBedsFree,
        'p_shock_beds_total': shockBedsTotal,
        'p_observation_beds_free': observationBedsFree,
        'p_observation_beds_total': observationBedsTotal,
        'p_accepting_red_patients': acceptingRedPatients,
        'p_operating_room_available': operatingRoomAvailable,
      },
    );
  }
}
