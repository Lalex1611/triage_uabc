import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_section_data.dart';

/// Tarjeta blanca del perfil (mockup 13): "Capacidad de urgencias" y
/// "Guardia de hoy"
class MedicoProfileSection extends StatelessWidget {
  const MedicoProfileSection({super.key, required this.data});

  final MedicoProfileSectionData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (data.actionLabel != null)
                TextButton(
                  onPressed: data.onActionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1C69AA),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(data.actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < data.rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEDF1F4)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.rows[i].label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3F4850),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    data.rows[i].value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (data.footnote != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                data.footnote!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF8A949E),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
