import 'package:flutter/material.dart';

/// Estado reportado por el paramédico: tipos de lesión, método de
/// clasificación (START) y su descripción
class MedicoReviewReportedState extends StatelessWidget {
  const MedicoReviewReportedState({
    super.key,
    required this.injuries,
    required this.description,
    this.startTriageMode,
  });

  final List<String> injuries;
  final String? description;
  final String? startTriageMode;

  @override
  Widget build(BuildContext context) {
    if (injuries.isEmpty && description == null && startTriageMode == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'El paramédico no registró una descripción.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8A949E)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (injuries.isNotEmpty) ...[
            const _Label('Lesiones'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final i in injuries) _Chip(i)],
            ),
            const SizedBox(height: 12),
          ],
          if (startTriageMode != null) ...[
            const _Label('Clasificación'),
            Text(
              'Triage START · $startTriageMode',
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
          ],
          if (description != null) ...[
            const _Label('Descripción del paramédico'),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5C6670),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE3EA)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1A1A1A)),
      ),
    );
  }
}
