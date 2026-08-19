import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_actions_data.dart';

class StartTriageActionsWidget extends StatelessWidget {
  final StartTriageActionsData data;

  const StartTriageActionsWidget({super.key, required this.data});

  static const double _buttonScale = 0.85;
  static const double _buttonHeight = 40 * _buttonScale;
  static const double _buttonRadius = 26;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!data.hasPhotos) ...[
            _buildCancelReturnButton(),
            const SizedBox(width: 14),
            _buildSkipButton(),
          ] else ...[
            _buildSkipButton(),
            const SizedBox(width: 14),
            _buildRegisterButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelReturnButton() {
    return GestureDetector(
      onTap: data.onCancelOrReturn,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20.4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_buttonRadius),
          border: Border.all(
            color: const Color(0xFF999A9D),
            width: 0.22,
          ), // Stroke 0.22 999A9D
        ),
        alignment: Alignment.center,
        child: Text(
          'Cancelar/Regresar',
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: const Color(0xFF999A9D),
            fontSize: 13.6,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: data.onSkip,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 27.2),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Fill 1A1A1A
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        alignment: Alignment.center,
        child: Text(
          'Omitir',
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 13.6,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: data.onRegister,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20.4),
        decoration: BoxDecoration(
          color: const Color(0xFF22A63C), // Verde típico
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 15.3,
            ),
            const SizedBox(width: 6.8),
            Text(
              'Registrar',
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 13.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
