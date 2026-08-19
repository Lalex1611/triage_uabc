import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/auth/domain/constants/auth_role_type.dart';

class AuthActionButton extends StatelessWidget {
  final AuthRoleType roleType;
  final VoidCallback onTap;

  const AuthActionButton({
    super.key,
    required this.roleType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 172,
        height: 38,
        decoration: BoxDecoration(
          color: roleType.primaryColor,
          borderRadius: BorderRadius.circular(
            19,
          ), // Corner radius 19 para forma circular
        ),
        child: Center(
          child: Text(
            'Iniciar sesión',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
