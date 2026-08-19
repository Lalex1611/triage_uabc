import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Dialogo de confirmacion sobre cobertura de seguro antes de finalizar traslado
class TransferInsuranceQuestionDialog extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onYesTap;
  final VoidCallback onNoTap;

  const TransferInsuranceQuestionDialog({
    super.key,
    required this.onBackTap,
    required this.onYesTap,
    required this.onNoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Rojo
            Container(
              color: const Color(0xFFCE1125),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBackTap,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '¿El paciente cuenta con seguro médico?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // Para balancear
                ],
              ),
            ),

            /* Espacio vacío solicitado de "como 60 puntos" (o más para acercar al dedo) */
            const SizedBox(
              height: 200,
            ), // Usamos 200 para empujar los botones bien abajo como en la imagen
            /* Botones No / Sí */
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onNoTap,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCE1125),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'No',
                          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: onYesTap,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E9B3D), // Verde
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Sí',
                          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
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
