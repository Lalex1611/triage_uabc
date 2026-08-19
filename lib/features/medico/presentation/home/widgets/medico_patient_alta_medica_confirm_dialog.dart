import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// Confirma cambio de estado «Recibido» → alta médica
class MedicoPatientAltaMedicaConfirmDialog extends StatelessWidget {
  const MedicoPatientAltaMedicaConfirmDialog({
    super.key,
    required this.onBackTap,
    required this.onConfirmTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onConfirmTap;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Registrar alta médica?',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'El paciente pasará de «Recibido» a «Alta médica». '
              '¿Desea continuar?',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _button(
                    label: 'NO, VOLVER',
                    filled: false,
                    onTap: onBackTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _button(
                    label: 'SÍ, DAR DE ALTA',
                    filled: true,
                    onTap: onConfirmTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryMedico : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryMedico),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
            fontSize: 12,
            color: filled ? Colors.white : AppColors.primaryMedico,
          ),
        ),
      ),
    );
  }
}
