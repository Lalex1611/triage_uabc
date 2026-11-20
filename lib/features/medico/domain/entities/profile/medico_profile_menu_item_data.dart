import 'package:flutter/material.dart';

/// Opción del cuadro de ajustes del perfil (Notificaciones, Privacidad, ...)
class MedicoProfileMenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MedicoProfileMenuItemData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
