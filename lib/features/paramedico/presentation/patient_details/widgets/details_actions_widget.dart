import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_actions_data.dart';
import 'package:sistema_triage/shared/widgets/app_sticky_action_bar.dart';

class DetailsActionsWidget extends StatelessWidget {
  final DetailsActionsData data;

  const DetailsActionsWidget({super.key, required this.data});

  static const double _buttonRadius = 16;

  @override
  Widget build(BuildContext context) {
    if (!data.canEdit) return const SizedBox();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        child: AppStickyActionRow(
          leading: _buildCancelButton(),
          trailing: _buildSaveButton(),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: data.onCancelTap,
      child: Container(
        height: 32,
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
              fontSize: 16.15,
              color: const Color(0xFFCE1125),
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: data.onSaveTap,
      child: Container(
        height: 35,
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
            'GUARDAR',
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
