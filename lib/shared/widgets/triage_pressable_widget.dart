import 'package:flutter/material.dart';

/// Envoltorio reutilizable para botones "planos" (Container + GestureDetector,
/// sin Material/InkWell) que necesitan feedback visual al presionar.
///
/// [builder] recibe si el botón está presionado para que cada sitio de uso
/// refuerce su propia sombra/decoración sin anidar contenedores extra.
class TriagePressable extends StatefulWidget {
  const TriagePressable({super.key, required this.builder, this.onTap});

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<TriagePressable> createState() => _TriagePressableState();
}

class _TriagePressableState extends State<TriagePressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.builder(context, _pressed),
      ),
    );
  }
}

/// Sombra reforzada estándar para el estado presionado de [TriagePressable].
List<BoxShadow> triagePressedShadow({required bool pressed}) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: pressed ? 0.28 : 0.1),
      blurRadius: pressed ? 10 : 4,
      offset: Offset(0, pressed ? 1 : 2),
    ),
  ];
}
