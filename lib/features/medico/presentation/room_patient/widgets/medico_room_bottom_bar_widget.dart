import 'package:flutter/material.dart';

/// Botonera fija inferior del paciente en sala (mockup 06): "Agregar nota de
/// atención" arriba y "Dar alta médica" en verde abajo
class MedicoRoomBottomBar extends StatelessWidget {
  const MedicoRoomBottomBar({
    super.key,
    this.onAddNoteTap,
    this.onDischargeTap,
    this.busy = false,
  });

  /// Null oculta el botón (p. ej. paciente ya dado de alta)
  final VoidCallback? onAddNoteTap;

  /// Null cuando el paciente ya fue dado de alta
  final VoidCallback? onDischargeTap;
  final bool busy;

  static const _green = Color(0xFF1E9E52);
  static const _primary = Color(0xFF1C69AA);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const text = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onAddNoteTap != null) ...[
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onAddNoteTap,
                icon: const Icon(Icons.note_add_outlined, size: 20),
                label: const Text('Agregar nota de atención'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  shape: shape,
                  textStyle: text,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 50,
            child: onDischargeTap == null
                ? Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Paciente dado de alta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _green,
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: busy ? null : onDischargeTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: _green.withValues(alpha: 0.6),
                      shape: shape,
                      textStyle: text,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Dar alta médica'),
                  ),
          ),
        ],
      ),
    );
  }
}
