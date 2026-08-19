import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

class AuthConsultButton extends StatelessWidget {
  final VoidCallback onTap;

  const AuthConsultButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
        height: 42.7,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(31.26),
          border: Border.all(color: Colors.black, width: 0.24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppIcons.authSearchMain, width: 18, height: 18),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultar estado',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 9,
                    color: const Color(0xFF999A9D),
                    height: 1.1,
                  ),
                ),
                Text(
                  'del paciente',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 9,
                    color: const Color(0xFF999A9D),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
