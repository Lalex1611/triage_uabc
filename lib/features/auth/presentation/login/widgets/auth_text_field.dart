import 'package:flutter/material.dart';
import 'package:sistema_triage/features/auth/domain/constants/auth_role_type.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Campo de acceso: conserva el límite de 60 caracteres del formulario actual.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final AuthRoleType roleType;
  final bool isPassword;
  final ValueChanged<String> onChanged;
  final VoidCallback? onForgotPassword;
  final TextEditingController? controller;
  final bool hasError;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.roleType,
    this.isPassword = false,
    required this.onChanged,
    this.onForgotPassword,
    this.controller,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(
      Color color, [
      double width = TriageSizes.stroke,
    ]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(TriageRadii.md),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: TriageTextStyles.labelMedium.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
              const SizedBox(height: TriageSpacing.sm),
              TextField(
                controller: controller,
                obscureText: isPassword,
                maxLength: 60,
                onChanged: onChanged,
                style: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: hint,
                  hintStyle: TriageTextStyles.bodyMedium.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: TriageColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TriageSpacing.lg,
                    vertical: TriageSpacing.md,
                  ),
                  enabledBorder: border(
                    hasError ? TriageColors.danger : TriageColors.borderMedium,
                  ),
                  focusedBorder: border(
                    hasError ? TriageColors.danger : context.triageRole.accent,
                    TriageSizes.strokeStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPassword && onForgotPassword != null) ...[
          const SizedBox(height: TriageSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: context.triageRole.accent,
                textStyle: TriageTextStyles.labelMedium,
                minimumSize: const Size(0, TriageSizes.touchTarget),
                padding: const EdgeInsets.symmetric(vertical: TriageSpacing.md),
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
        ],
      ],
    );
  }
}
