import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/auth/domain/constants/auth_role_type.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String hint;
  final AuthRoleType roleType;
  final bool isPassword;
  final ValueChanged<String> onChanged;
  final VoidCallback? onForgotPassword;
  final TextEditingController? controller;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.roleType,
    this.isPassword = false,
    required this.onChanged,
    this.onForgotPassword,
    this.controller,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  int _currentLength = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword,
            maxLength: 60,
            onChanged: (val) {
              setState(() => _currentLength = val.length);
              widget.onChanged(val);
            },
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 12,
              color: const Color(
                0xFF999A9D,
              ), // Como se ve en la imagen el hint/texto
            ),
            decoration: InputDecoration(
              counterText:
                  '', // Ocultamos el counter interno para dibujarlo abajo
              floatingLabelBehavior: FloatingLabelBehavior.always,
              label: RichText(
                text: TextSpan(
                  text: widget.label,
                  style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                    color: widget.roleType.primaryColor,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: ' *',
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        color: const Color(0xFFCE1125), // Asterisco rojo
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              hintText: widget.hint,
              hintStyle: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 12,
                color: const Color(0xFF999A9D),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: widget.roleType.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: widget.roleType.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: (() {
            MainAxisAlignment alignment = MainAxisAlignment.end;
            if (widget.isPassword) {
              alignment = MainAxisAlignment.spaceBetween;
            }
            return alignment;
          })(),
          children: [
            if (widget.isPassword)
              Text(
                '$_currentLength/60',
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 10,
                  color: Colors.black, // Color aproximado para el contador
                ),
              ),
            if (widget.isPassword && widget.onForgotPassword != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: widget.onForgotPassword,
                    child: Text(
                      '¿olvidaste tu contraseña?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        fontSize: 10,
                        color: widget.roleType.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            if (!widget.isPassword)
              Text(
                '$_currentLength/60',
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
