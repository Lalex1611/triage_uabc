import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_attention_note.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/medico_room_format.dart';

/// "Notas de atención" del paciente en sala: las notas que agregan los médicos,
/// de la más reciente a la más antigua, con autor y hora
class MedicoRoomNotes extends StatelessWidget {
  const MedicoRoomNotes({
    super.key,
    required this.notes,
    required this.now,
    this.loadFailed = false,
    this.onRetry,
  });

  final List<MedicoAttentionNote> notes;
  final DateTime now;

  /// La última lectura falló: se avisa y se ofrece reintentar en lugar de
  /// decir "Sin notas" (si ya había notas, se siguen mostrando)
  final bool loadFailed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Notas de atención',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          if (loadFailed) ...[
            MedicoRoomLoadError(
              message: notes.isEmpty
                  ? 'No se pudieron cargar las notas.'
                  : 'No se pudieron actualizar las notas.',
              onRetry: onRetry,
              compact: true,
            ),
            const SizedBox(height: 10),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: loadFailed ? 0 : 110),
            child: notes.isEmpty
                ? loadFailed
                      ? const SizedBox.shrink()
                      : const Text(
                          'Sin notas de atención todavía.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8A949E),
                          ),
                        )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < notes.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 20, color: Color(0xFFEDF1F4)),
                        _note(notes[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _note(MedicoAttentionNote n) {
    final when = MedicoRoomFormat.historyTime(n.createdAt, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n.authorName == null ? when : '$when · ${n.authorName}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C6670),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          n.body,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

/// Aviso de que no se pudo leer algo de la vista en sala, con "Reintentar"
class MedicoRoomLoadError extends StatelessWidget {
  const MedicoRoomLoadError({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Dentro de otra tarjeta (sin borde propio)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: Color(0xFFC62828)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFFC62828)),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
    if (compact) return row;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7ED)),
      ),
      child: row,
    );
  }
}
