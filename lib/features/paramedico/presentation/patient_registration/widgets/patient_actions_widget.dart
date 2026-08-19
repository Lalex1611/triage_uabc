import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_actions_data.dart';
import 'package:sistema_triage/shared/widgets/app_sticky_action_bar.dart';

class PatientActionsWidget extends StatelessWidget {
  final PatientActionsData data;

  const PatientActionsWidget({super.key, required this.data});

  static const double _buttonRadius = 16;

  @override
  Widget build(BuildContext context) {
    return AppStickyActionBar(
      child: AppStickyActionRow(
        leading: _buildCancelButton(),
        trailing: _buildConfirmButton(),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: data.onCancelTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_buttonRadius),
          border: Border.all(color: const Color(0xFFCE1125), width: 0.43),
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
            'CANCELAR',
            style: AppTextStyles.ESC_ExtraBold_titleLarge.copyWith(
              fontSize: 12.75,
              color: const Color(0xFFCE1125),
              height: 1.1,
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
        decoration: BoxDecoration(
          color: const Color(0xFFCE1125),
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
            'CONFIRMAR',
            style: AppTextStyles.ESC_ExtraBold_titleLarge.copyWith(
              fontSize: 12.75,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
