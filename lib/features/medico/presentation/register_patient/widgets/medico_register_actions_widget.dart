import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_actions_data.dart';

class MedicoRegisterActionsWidget extends StatelessWidget {
  final MedicoRegisterActionsData data;

  const MedicoRegisterActionsWidget({super.key, required this.data});

  static const double _buttonHeight = 32.3;
  static const double _buttonRadius = 15;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildCancelButton()),
            const SizedBox(width: 14),
            Expanded(child: _buildConfirmButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: data.onCancelTap,
      child: Container(
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_buttonRadius),
          border: Border.all(color: AppColors.primaryMedico, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.cancelLabel,
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              color: AppColors.primaryMedico,
              fontSize: 13.6,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: data.onConfirmTap,
      child: Container(
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.primaryMedico,
          borderRadius: BorderRadius.circular(_buttonRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.confirmLabel,
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              color: Colors.white,
              fontSize: 13.6,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
