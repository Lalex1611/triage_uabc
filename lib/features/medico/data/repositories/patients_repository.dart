import 'dart:math';

import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/geo/geo_location_parser.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/patient_triage_history_entry.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PatientsRepository {
  static const _patientCardSelect =
      'id, sync_client_id, display_name, triage_color, status, created_at, location, '
      'regulation_folio, descriptive_notes, estimated_arrival_at, '
      'ambulancias_unidades ( numero_economico )';

  PatientsRepository({SupabaseClient? client})
    : _client =
          client ??
          (SupabaseEnv.isConfigured ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  SupabaseClient get _c {
    final x = _client;
    if (x == null) throw Exception('El servicio no se encuentra configurado en este momento');
    return x;
  }

  Future<List<MedicoPatientCardData>> fetchForMedico({
    required String? hospitalIdFromProfile,
  }) async {
    var builder = _c
        .from('patients')
        .select(_patientCardSelect)
        .eq('is_archived', false)
        .eq('is_deleted', false);

    if (hospitalIdFromProfile != null && hospitalIdFromProfile.isNotEmpty) {
      builder = builder.eq('hospital_id', hospitalIdFromProfile);
    }

    final rows = await builder.order('created_at', ascending: false);
    final list = rows as List<dynamic>;
    return [
      for (var i = 0; i < list.length; i++)
        _mapRow(list[i] as Map<String, dynamic>, number: i + 1),
    ];
  }

  Future<void> updateLifecycleStatus({
    required String patientId,
    required String status,
  }) async {
    await _c.from('patients').update({'status': status}).eq('id', patientId);
  }

  Future<void> receivePatient({required String patientId}) async {
    final updated = await _c
        .from('patients')
        .update({'status': 'recibido'})
        .eq('id', patientId)
        .eq('status', 'trasladando')
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw Exception('El paciente ya no se encuentra en traslado');
    }
  }

  Future<void> cancelTransfer({
    required String patientId,
    required String reason,
  }) async {
    await _c.rpc(
      'medico_cancel_patient_transfer',
      params: {'p_patient_id': patientId, 'p_reason': reason.trim()},
    );
  }

  /// Se guardan los signos vitales del paciente
  Future<void> updateVitalSigns({
    required String patientId,
    required Map<String, dynamic> vitals,
  }) async {
    await _c
        .from('patients')
        .update({'vital_signs': vitals})
        .eq('id', patientId);
  }

  Future<Map<String, dynamic>> fetchVitalSigns(String patientId) async {
    final row = await _c
        .from('patients')
        .select('vital_signs')
        .eq('id', patientId)
        .eq('is_deleted', false)
        .maybeSingle();
    if (row == null) return {};
    final raw = row['vital_signs'];
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  /// Obtiene el historial de triage y los cambios de estado del paciente
  Future<List<PatientTriageHistoryEntry>> fetchTriageHistory(
    String patientId,
  ) async {
    final rows = await _c
        .from('patient_state_history')
        .select(
          'id, patient_id, old_triage_color, new_triage_color, old_status, new_status, actor_role, changed_fields, created_at',
        )
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    final list = rows as List<dynamic>;
    return [
      for (final r in list)
        _mapHistoryRow(r as Map<String, dynamic>),
    ];
  }

  static PatientTriageHistoryEntry _mapHistoryRow(Map<String, dynamic> row) {
    final oldColorRaw = row['old_triage_color'] as String?;
    final newColorRaw = row['new_triage_color'] as String? ?? 'amarillo';
    final changedFieldsRaw = row['changed_fields'] as List<dynamic>? ?? [];
    final createdAtRaw = row['created_at'] as String?;
    final dt = createdAtRaw != null
        ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
        : DateTime.now();

    return PatientTriageHistoryEntry(
      id: row['id'] as String? ?? '',
      patientId: row['patient_id'] as String? ?? '',
      oldTriageColor: _parseMedicoTriageColor(oldColorRaw),
      newTriageColor:
          _parseMedicoTriageColor(newColorRaw) ?? MedicoTriageCategory.amarillo,
      oldStatus: row['old_status'] as String?,
      newStatus: row['new_status'] as String? ?? 'registrado',
      actorRole: row['actor_role'] as String?,
      changedFields: [for (final f in changedFieldsRaw) f.toString()],
      changedAt: dt,
    );
  }

  static MedicoTriageCategory? _parseMedicoTriageColor(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase().trim()) {
      case 'rojo':
        return MedicoTriageCategory.rojo;
      case 'naranja':
        return MedicoTriageCategory.naranja;
      case 'amarillo':
        return MedicoTriageCategory.amarillo;
      case 'verde':
        return MedicoTriageCategory.verde;
      case 'azul':
        return MedicoTriageCategory.azul;
      default:
        return null;
    }
  }

  /// Registra un ingreso al hospital sin traslado quedando en estado recibido
  Future<({String patientId, String consultationCode})> registerWalkInPatient({
    required String hospitalId,
    required String triageColor,
    required String displayName,
    required Map<String, dynamic> demographics,
    Map<String, dynamic>? vitalSigns,
  }) async {
    final uidAuth = _c.auth.currentUser?.id;
    if (uidAuth == null) throw Exception('La sesión no es válida o ha expirado');

    final insertRow = <String, dynamic>{
      'sync_client_id': const Uuid().v4(),
      'hospital_id': hospitalId,
      'triage_color': triageColor,
      'status': 'recibido',
      'created_by': uidAuth,
      'demographics': demographics,
    };
    final dn = displayName.trim();
    if (dn.isNotEmpty) insertRow['display_name'] = dn;
    if (vitalSigns != null && vitalSigns.isNotEmpty) {
      insertRow['vital_signs'] = vitalSigns;
    }

    final inserted = await _c
        .from('patients')
        .insert(insertRow)
        .select('id')
        .single();

    final patientId = inserted['id'] as String;

    final code = await _insertUniqueConsultationCode(
      patientId: patientId,
      createdBy: uidAuth,
    );

    return (patientId: patientId, consultationCode: code);
  }

  Future<String> _insertUniqueConsultationCode({
    required String patientId,
    required String createdBy,
  }) async {
    final rnd = Random.secure();
    for (var attempt = 0; attempt < 12; attempt++) {
      final code = _randomConsultationCode(rnd);
      if (await _consultationCodeExists(code)) continue;
      try {
        await _c.from('consultation_codes').insert({
          'patient_id': patientId,
          'code': code,
          'created_by': createdBy,
        });
        return code;
      } on PostgrestException catch (e) {
        if (!_isConsultationCodeCollision(e)) rethrow;
        continue;
      }
    }
    throw Exception('No pudimos generar un código de consulta único');
  }

  String _randomConsultationCode(Random rnd) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buf = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buf.write(alphabet[rnd.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }

  Future<bool> _consultationCodeExists(String code) async {
    final rows = await _c
        .from('consultation_codes')
        .select('id')
        .eq('code', code)
        .limit(1);
    return (rows as List<dynamic>).isNotEmpty;
  }

  bool _isConsultationCodeCollision(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '23505' ||
        message.contains('duplicate key') ||
        message.contains('unique');
  }

  Future<List<MedicoPatientCardData>> fetchRejectedTransfers({
    required String hospitalId,
  }) async {
    final rows = await _c
        .from('medico_rejected_transfers')
        .select('patient_id, reason, patients($_patientCardSelect)')
        .eq('hospital_id', hospitalId)
        .order('created_at', ascending: false);

    final list = rows as List<dynamic>;
    final out = <MedicoPatientCardData>[];
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      final p = m['patients'];
      if (p is! Map<String, dynamic>) continue;
      final reason = (m['reason'] as String?)?.trim() ?? '';
      final card = _mapRow(p, number: out.length + 1).copyWith(
        footerNote: reason.isEmpty ? null : 'Motivo rechazo: $reason',
        isRejectedTransfer: true,
      );
      out.add(card);
    }
    return out;
  }

  Future<List<MedicoNotificationItem>> fetchMedicoNotifications() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _c
        .from('medico_notifications')
        .select()
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .limit(100);

    final list = rows as List<dynamic>;
    return list
        .map((e) => MedicoNotificationItem.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markMedicoNotificationRead(String notificationId) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw Exception('La sesión no es válida o ha expirado');
    await _c
        .from('medico_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('recipient_id', uid);
  }

  MedicoPatientCardData _mapRow(Map<String, dynamic> row, {int? number}) {
    final id = row['id'] as String;
    final triageRaw = row['triage_color'] as String? ?? 'amarillo';
    final statusRaw = row['status'] as String? ?? 'registrado';
    final createdAt = row['created_at'] as String?;
    final location = row['location'];
    final folio = row['regulation_folio'] as String?;
    final notes = row['descriptive_notes'] as String?;
    final etaAt = row['estimated_arrival_at'] as String?;
    final unit = row['ambulancias_unidades'];
    final displayNameRaw = (row['display_name'] as String?)?.trim();

    final displayName = (displayNameRaw != null && displayNameRaw.isNotEmpty)
        ? displayNameRaw
        : (folio != null && folio.isNotEmpty)
        ? folio
        : (notes != null && notes.isNotEmpty)
        ? notes.split('\n').first
        : 'Paciente ${id.substring(0, 8)}';

    final dt = createdAt != null ? DateTime.tryParse(createdAt) : null;
    final dateStr = dt != null ? _fmt(dt) : '—';

    final coords = _coordsFromLocation(location);
    final eta = _fmtEta(etaAt);

    String unitLabel = 'Unidad no registrada';
    if (unit is Map<String, dynamic>) {
      final ne = unit['numero_economico'] as String?;
      if (ne != null && ne.isNotEmpty) {
        unitLabel = 'Unidad: $ne';
      }
    }

    final shortId = id.length >= 6
        ? id.substring(0, 6).toUpperCase()
        : id.toUpperCase();
    return MedicoPatientCardData(
      patientRecordId: id,
      id: 'PAC-$shortId',
      number: number ?? 1,
      triageCategory: _triageFromDb(triageRaw),
      name: displayName,
      dateStr: dateStr,
      coordinates: coords,
      eta: eta,
      ambulanceUnit: unitLabel,
      status: _lifecycleFromDb(statusRaw),
      footerNote: null,
    );
  }

  static PatientStatus _lifecycleFromDb(String raw) {
    switch (raw) {
      case 'registrado':
        return PatientStatus.registrado;
      case 'en_espera':
        return PatientStatus.enEspera;
      case 'trasladando':
        return PatientStatus.trasladando;
      case 'recibido':
        return PatientStatus.recibido;
      case 'alta_medica':
        return PatientStatus.alta;
      default:
        return PatientStatus.registrado;
    }
  }

  static TriageCategory _triageFromDb(String raw) {
    switch (raw) {
      case 'rojo':
        return TriageCategory.rojo;
      case 'naranja':
        return TriageCategory.naranja;
      case 'amarillo':
        return TriageCategory.amarillo;
      case 'verde':
        return TriageCategory.verde;
      case 'azul':
        return TriageCategory.azul;
      case 'negro':
        return TriageCategory.negro;
      default:
        return TriageCategory.amarillo;
    }
  }

  static String _fmt(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$min:$ss';
  }

  static String _coordsFromLocation(dynamic location) =>
      GeoLocationParser.formatForDisplay(location);

  static String _fmtEta(String? iso) {
    if (iso == null) return '—';
    final t = DateTime.tryParse(iso);
    if (t == null) return '—';
    final now = DateTime.now();
    final diff = t.difference(now);
    if (diff.inMinutes.abs() > 24 * 60) return 'ETA ${_fmt(t)}';
    if (diff.inMinutes >= 0) {
      return 'A ${diff.inMinutes} min…';
    }
    return '—';
  }
}
