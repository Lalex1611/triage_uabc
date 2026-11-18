import 'package:flutter/material.dart';

/// Botonera fija inferior de las confirmaciones de traslado (mockups 03 y 04):
/// botón principal (azul para recibir, rojo para rechazar) y uno de texto
/// abajo ("Cancelar" por defecto)
class MedicoTransferBottomBar extends StatelessWidget {
  const MedicoTransferBottomBar({
    super.key,
    required this.primaryLabel,
    required this.primaryColor,
    required this.onPrimaryTap,
    required this.onCancelTap,
    this.busy = false,
    this.cancelLabel = 'Cancelar',
  });

  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback onPrimaryTap;
  final VoidCallback onCancelTap;
  final bool busy;

  /// Texto del botón de abajo ("Cancelar", "Volver a entrantes", ...)
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 8 + bottomInset),
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
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: busy ? null : onPrimaryTap,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
                  : Text(primaryLabel),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: busy ? null : onCancelTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: Text(cancelLabel),
          ),
        ],
      ),
    );
  }
}
