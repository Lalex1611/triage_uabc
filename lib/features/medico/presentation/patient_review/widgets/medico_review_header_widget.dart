import 'package:flutter/material.dart';

/// Encabezado de las pantallas de paciente entrante (mockups 02, 03 y 04):
/// atrás o cerrar, título y subtítulo
class MedicoReviewHeader extends StatelessWidget {
  const MedicoReviewHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBackTap,
    this.leadingIcon = Icons.arrow_back,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBackTap;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: Icon(leadingIcon, size: 24),
            color: const Color(0xFF1A1A1A),
            tooltip: leadingIcon == Icons.close ? 'Cerrar' : 'Atrás',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5C6670),
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
