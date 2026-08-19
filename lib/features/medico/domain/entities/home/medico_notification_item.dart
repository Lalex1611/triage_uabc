/// Notificación in-app para el módulo médico (`public.medico_notifications`)
class MedicoNotificationItem {
  final String id;
  final String title;
  final String body;
  final String kind;
  final String? patientId;
  final DateTime createdAt;
  final DateTime? readAt;

  const MedicoNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.patientId,
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory MedicoNotificationItem.fromRow(Map<String, dynamic> row) {
    final createdRaw = row['created_at'] as String?;
    final readRaw = row['read_at'] as String?;
    return MedicoNotificationItem(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      kind: row['kind'] as String? ?? 'generic',
      patientId: row['patient_id'] as String?,
      createdAt:
          createdRaw != null
              ? DateTime.tryParse(createdRaw) ?? DateTime.now()
              : DateTime.now(),
      readAt: readRaw != null ? DateTime.tryParse(readRaw) : null,
    );
  }
}
