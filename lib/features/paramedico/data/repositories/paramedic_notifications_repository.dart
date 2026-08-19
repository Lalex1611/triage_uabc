import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/notifications/paramedic_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParamedicNotificationsRepository {
  ParamedicNotificationsRepository({SupabaseClient? client})
      : _client = client ?? (SupabaseEnv.isConfigured ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  SupabaseClient get _c {
    final x = _client;
    if (x == null) throw Exception('El servicio no se encuentra configurado en este momento');
    return x;
  }

  Future<int> countUnread() async {
    final items = await listRecent(limit: 100);
    return items.where((n) => n.isUnread).length;
  }

  Future<List<ParamedicNotification>> listRecent({int limit = 50}) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _c
        .from('paramedic_notifications')
        .select('id, title, body, kind, patient_id, metadata, created_at, read_at')
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => _map(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    await _c.from('paramedic_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', notificationId);
  }

  ParamedicNotification _map(Map<String, dynamic> j) {
    final meta = j['metadata'];
    String? patientName;
    if (meta is Map<String, dynamic>) {
      patientName = meta['patient_display_name'] as String?;
    }
    return ParamedicNotification(
      id: j['id'] as String,
      title: j['title'] as String? ?? 'Notificación',
      body: j['body'] as String? ?? '',
      kind: j['kind'] as String? ?? 'general',
      patientId: j['patient_id'] as String?,
      patientDisplayName: patientName,
      createdAt: DateTime.parse(j['created_at'] as String),
      readAt: j['read_at'] == null ? null : DateTime.tryParse(j['read_at'] as String),
    );
  }
}
