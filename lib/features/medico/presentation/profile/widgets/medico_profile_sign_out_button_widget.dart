import 'package:flutter/material.dart';

/// Botón rojo "Cerrar sesión" al final del perfil
class MedicoProfileSignOutButton extends StatelessWidget {
  const MedicoProfileSignOutButton({super.key, required this.onTap});

  final VoidCallback onTap;

  static const red = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Cerrar sesión'),
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
