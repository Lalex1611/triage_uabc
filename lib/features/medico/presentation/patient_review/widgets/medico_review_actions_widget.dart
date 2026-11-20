import 'package:flutter/material.dart';

/// Botonera fija inferior (mockup 02): "Rechazar" y "Aceptar paciente"
class MedicoReviewActions extends StatelessWidget {
  const MedicoReviewActions({
    super.key,
    required this.onRejectTap,
    required this.onAcceptTap,
    this.busy = false,
  });

  final VoidCallback onRejectTap;
  final VoidCallback onAcceptTap;
  final bool busy;

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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: busy ? null : onRejectTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFFD3DBE3)),
                  shape: shape,
                  textStyle: text,
                ),
                child: const Text('Rechazar'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: busy ? null : onAcceptTap,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: _primary.withValues(alpha: 0.6),
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
                    : const Text('Aceptar paciente'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
