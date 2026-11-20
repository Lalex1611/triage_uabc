import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_menu_item_data.dart';

/// Cuadro de opciones del perfil, debajo de "Guardia de hoy": cada fila con
/// icono, texto y flecha
class MedicoProfileMenu extends StatelessWidget {
  const MedicoProfileMenu({super.key, required this.items});

  final List<MedicoProfileMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7ED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, indent: 56, color: Color(0xFFEDF1F4)),
              _row(items[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(MedicoProfileMenuItemData item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Icon(item.icon, size: 22, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A949E)),
          ],
        ),
      ),
    );
  }
}
