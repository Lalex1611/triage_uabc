import 'package:flutter/material.dart';

/// Encabezado del perfil (mockup 13): atrás y "Mi perfil · Guardia actual"
class MedicoProfileHeader extends StatelessWidget {
  const MedicoProfileHeader({super.key, required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(Icons.arrow_back, size: 24),
            color: const Color(0xFF1A1A1A),
            tooltip: 'Atrás',
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi perfil',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Guardia actual',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF5C6670)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
