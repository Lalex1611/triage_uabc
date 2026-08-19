import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// Confirmación explícita antes de recibir un traslado en el hospital
class MedicoTransferAcceptConfirmDialog extends StatelessWidget {
  const MedicoTransferAcceptConfirmDialog({
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
              '¿Confirmar recepción del paciente?',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción marcará el traslado como recibido en el hospital.',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.58),
                height: 1.25,
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
                    label: 'SÍ, RECIBIR',
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
