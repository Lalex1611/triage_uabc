class ParamedicNotification {
  final String id;
  final String title;
  final String body;
  final String kind;
  final String? patientId;
  final String? patientDisplayName;
  final DateTime createdAt;
  final DateTime? readAt;

  const ParamedicNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.patientId,
    this.patientDisplayName,
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => readAt == null;
}
