import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Contenedor de los botones de acción principales (Cancelar / Crear Incidente)
class CreateIncidentActions extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onCreate;

  const CreateIncidentActions({super.key, this.onCancel, this.onCreate});

  static const double _buttonScale = 0.85;
  static const double _buttonWidth = 140 * _buttonScale;
  static const double _buttonHeight = 40 * _buttonScale;
  static const double _buttonRadius = 18;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCancelButton(context),
            const SizedBox(width: 31),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return InkWell(
      onTap: onCancel ?? () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(_buttonRadius),
      child: Container(
        width: _buttonWidth,
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_buttonRadius),
          border: Border.all(
            color: const Color(0xFF999A9D),
            width: 0.5, // 0.26 de Figma adaptado para ser visible
          ),
        ),
        child: Center(
          child: Text(
            'Cancelar',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 17,
              color: const Color(0xFF999A9D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return InkWell(
      onTap: onCreate,
      borderRadius: BorderRadius.circular(_buttonRadius),
      child: Container(
        width: _buttonWidth,
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFCE1125),
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        child: Center(
          child: Text(
            'Crear',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w500, // Medium en Figma
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
