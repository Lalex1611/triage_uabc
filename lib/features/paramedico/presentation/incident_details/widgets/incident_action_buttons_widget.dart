import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/app_sticky_action_bar.dart';

// Contenedor de botones de acción principales flotantes
class IncidentActionButtons extends StatelessWidget {
  final VoidCallback? onStartTap;
  final VoidCallback? onRegisterTap;

  const IncidentActionButtons({super.key, this.onStartTap, this.onRegisterTap});

  static const double _buttonRadius = 16;

  @override
  Widget build(BuildContext context) {
    return AppStickyActionBar(
      child: AppStickyActionRow(
        leading: _buildStartButton(),
        trailing: _buildRegisterButton(),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: onStartTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_buttonRadius),
          border: Border.all(color: AppColors.primaryParamedico, width: 0.43),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'INICIAR START',
            style: AppTextStyles.ESC_ExtraBold_titleLarge.copyWith(
              fontSize: 12.75,
              color: AppColors.primaryParamedico,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: onRegisterTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryParamedico,
          borderRadius: BorderRadius.circular(_buttonRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'REGISTRAR PACIENTE',
            style: AppTextStyles.ESC_ExtraBold_titleLarge.copyWith(
              fontSize: 18.7,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
