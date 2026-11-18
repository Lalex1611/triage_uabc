/// Nota de atención de un paciente en sala (`patient_attention_notes`)
class MedicoAttentionNote {
  final String id;
  final String body;
  final String? authorName;
  final DateTime createdAt;

  const MedicoAttentionNote({
    required this.id,
    required this.body,
    required this.createdAt,
    this.authorName,
  });

  static const maxLength = 2000;

  factory MedicoAttentionNote.fromRow(Map<String, dynamic> row) {
    final author = row['author'];
    final name = author is Map
        ? (author['full_name'] as String?)?.trim()
        : null;
    return MedicoAttentionNote(
      id: row['id'] as String,
      body: (row['body'] as String? ?? '').trim(),
      authorName: (name == null || name.isEmpty) ? null : name,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
