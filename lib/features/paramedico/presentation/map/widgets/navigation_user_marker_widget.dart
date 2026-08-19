import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';

// Marcador de ubicacion del usuario durante navegacion
class NavigationUserMarker extends StatelessWidget {
  const NavigationUserMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryMedico,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.navigation_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
