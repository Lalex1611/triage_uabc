// flutter run -t test/features/auth/presentation/login/forgot_password_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/auth/presentation/login/forgot_password_screen.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: const ForgotPasswordScreen(),
  ),
);
