import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_attention_note.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/medico_room_format.dart';

/// "Notas de atención" del paciente en sala: las notas que agregan los médicos,
/// de la más reciente a la más antigua, con autor y hora
class MedicoRoomNotes extends StatelessWidget {
  const MedicoRoomNotes({super.key, required this.notes, required this.now});

  final List<MedicoAttentionNote> notes;
  final DateTime now;

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
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 110),
            child: notes.isEmpty
                ? const Text(
                    'Sin notas de atención todavía.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A949E)),
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
