import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Dialogo de captura de folio de regulacion para completar el traslado
class TransferFolioDialog extends StatefulWidget {
  final VoidCallback onBackTap;
  final Function(String) onSubmit;

  const TransferFolioDialog({
    super.key,
    required this.onBackTap,
    required this.onSubmit,
  });

  @override
  State<TransferFolioDialog> createState() => _TransferFolioDialogState();
}

class _TransferFolioDialogState extends State<TransferFolioDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: const Color(0xFFCE1125), // Fondo rojo en todo el body
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /* Header Rojo (sin borde inferior en este caso) */
            Container(
              padding: const EdgeInsets.only(left: 16, top: 14, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBackTap,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Folio paciente (opcional):',
                    style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() {}),
                      maxLength: 30,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        counterText: '', // Ocultar counter default
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '(Código proporcionado por el CRUM)',
                        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${_controller.text.length}/30',
                        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => widget.onSubmit(_controller.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasText ? 'Aceptar' : 'Omitir',
                              style:
                                  AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                                    color: const Color(0xFFCE1125),
                                    fontSize: 14,
                                  ),
                            ),
                            if (hasText) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check,
                                color: Color(0xFFCE1125),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
