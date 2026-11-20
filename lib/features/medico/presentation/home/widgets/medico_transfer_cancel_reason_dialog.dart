import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// Motivo por el que el hospital no puede recibir al paciente
class MedicoTransferCancelReasonDialog extends StatefulWidget {
  const MedicoTransferCancelReasonDialog({
    super.key,
    required this.onBackTap,
    required this.onSubmit,
  });

  final VoidCallback onBackTap;
  final ValueChanged<String> onSubmit;

  @override
  State<MedicoTransferCancelReasonDialog> createState() =>
      _MedicoTransferCancelReasonDialogState();
}

class _MedicoTransferCancelReasonDialogState extends State<MedicoTransferCancelReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: AppColors.primaryMedico,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onBackTap,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Text(
              'Motivo de cancelación',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Indique por qué no se puede recibir al paciente en este momento.',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              maxLines: 5,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Escriba el motivo…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: canSubmit ? () => widget.onSubmit(_controller.text.trim()) : null,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: canSubmit ? Colors.white : Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ENVIAR CANCELACIÓN',
                  style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                    fontSize: 14,
                    color: AppColors.primaryMedico,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
