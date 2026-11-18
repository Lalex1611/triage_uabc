import 'package:flutter/material.dart';

/// Tarjeta de color del triage (mockup 02): "ROJO · INMEDIATO", nombre y edad,
/// y la pastilla de llegada con la unidad
class MedicoReviewTriageBanner extends StatelessWidget {
  const MedicoReviewTriageBanner({
    super.key,
    required this.color,
    required this.levelLabel,
    required this.title,
    required this.arrivalLabel,
    this.darkText = false,
  });

  final Color color;

  /// p. ej. "ROJO · INMEDIATO"
  final String levelLabel;

  /// p. ej. "Alberto Pérez, 34 años"
  final String title;

  /// p. ej. "Llega en 6 minutos · Unidad A-12"
  final String arrivalLabel;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            levelLabel,
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: (darkText ? Colors.black : Colors.white).withValues(
                alpha: 0.16,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 18, color: fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    arrivalLabel,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
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
