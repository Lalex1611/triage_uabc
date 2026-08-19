import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// SnackBars alineados a [AppTextStyles] / paleta (ARCHITECTURE_GUIDE §7)
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final bg = isError ? AppColors.primaryParamedico : const Color(0xFF424242);

  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: bg,
      content: Text(
        message,
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
          fontSize: 14,
          color: Colors.white,
          height: 1.25,
        ),
      ),
    ),
  );
}
