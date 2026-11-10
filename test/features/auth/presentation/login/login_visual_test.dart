import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/auth/presentation/login/login_screen.dart';

void main() {
  runApp(
    MaterialApp(
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    ),
  );
}
