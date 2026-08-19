import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_incoming_patient_actions_data.dart';

/// Acciones al pulsar un paciente en camino (Figma: cancelar traslado / recibir)
class MedicoIncomingPatientActionsDialog extends StatelessWidget {
  const MedicoIncomingPatientActionsDialog({super.key, required this.data});

  final MedicoIncomingPatientActionsData data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              data.patientName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Estado: ${data.currentStatusLabel}',
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            _actionButton(
              label: 'CANCELAR TRASLADO',
              filled: false,
              onTap: data.onCancelTransferTap,
            ),
            const SizedBox(height: 10),
            _actionButton(
              label: 'RECIBIR PACIENTE',
              filled: true,
              onTap: data.onReceivePatientTap,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: data.onCloseTap,
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryMedico : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryMedico, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
            fontSize: 14,
            color: filled ? Colors.white : AppColors.primaryMedico,
          ),
        ),
      ),
    );
  }
}
