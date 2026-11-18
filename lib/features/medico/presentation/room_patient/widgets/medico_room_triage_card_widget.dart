import 'package:flutter/material.dart';

/// Tarjeta de color del paciente en sala (mockup 06): nivel hospitalario,
/// "Rojo · atención inmediata" y tiempo en sala
class MedicoRoomTriageCard extends StatelessWidget {
  const MedicoRoomTriageCard({
    super.key,
    required this.color,
    required this.overline,
    required this.title,
    required this.subtitle,
    this.darkText = false,
  });

  final Color color;

  /// "TRIAGE HOSPITALARIO · NIVEL 1"
  final String overline;

  /// "Rojo · atención inmediata"
  final String title;

  /// "Recibido a las 14:52 · lleva 4 min en sala"
  final String subtitle;

  /// Texto oscuro para fondos claros (amarillo)
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final fg = darkText ? const Color(0xFF1A1A1A) : Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overline,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: fg.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
