import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'EncodeSansCondensed_mainTypo';

  /* ─── THIN (w100) ────────────────────────────────────────────────────────── */
  static const TextStyle ESC_Thin_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w100,
  );
  static const TextStyle ESC_Thin_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w100,
  );
  static const TextStyle ESC_Thin_bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w100,
  );
  static const TextStyle ESC_Thin_bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w100,
  );

  /* ─── EXTRA LIGHT (w200) ─────────────────────────────────────────────────── */
  static const TextStyle ESC_ExtraLight_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w200,
  );
  static const TextStyle ESC_ExtraLight_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w200,
  );
  static const TextStyle ESC_ExtraLight_bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w200,
  );

  /* ─── LIGHT (w300) ───────────────────────────────────────────────────────── */
  static const TextStyle ESC_Light_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w300,
  );
  static const TextStyle ESC_Light_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w300,
  );
  static const TextStyle ESC_Light_bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w300,
  );

  /* ─── REGULAR (w400) ─────────────────────────────────────────────────────── */
  static const TextStyle ESC_Regular_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle ESC_Regular_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle ESC_Regular_bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle ESC_Regular_bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /* ─── MEDIUM (w500) ──────────────────────────────────────────────────────── */
  static const TextStyle ESC_Medium_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle ESC_Medium_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle ESC_Medium_titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle ESC_Medium_bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle ESC_Medium_labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /* ─── SEMI BOLD (w600) ───────────────────────────────────────────────────── */
  static const TextStyle ESC_SemiBold_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle ESC_SemiBold_headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle ESC_SemiBold_titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle ESC_SemiBold_bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /* ─── BOLD (w700) ────────────────────────────────────────────────────────── */
  static const TextStyle ESC_Bold_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle ESC_Bold_displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle ESC_Bold_displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle ESC_Bold_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle ESC_Bold_titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  /* ─── EXTRA BOLD (w800) ──────────────────────────────────────────────────── */
  static const TextStyle ESC_ExtraBold_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle ESC_ExtraBold_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  /* ─── BLACK (w900) ───────────────────────────────────────────────────────── */
  static const TextStyle ESC_Black_displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle ESC_Black_titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );
}

final ThemeData appTheme = ThemeData(
  fontFamily: AppTextStyles.fontFamily,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFCE1125),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF1D71B8),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFFF001B),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
  ),
  textTheme: const TextTheme(
    displayLarge: AppTextStyles.ESC_Bold_displayLarge,
    displayMedium: AppTextStyles.ESC_Bold_displayMedium,
    displaySmall: AppTextStyles.ESC_Bold_displaySmall,
    headlineMedium: AppTextStyles.ESC_SemiBold_headlineMedium,
    titleLarge: AppTextStyles.ESC_Bold_titleLarge,
    titleMedium: AppTextStyles.ESC_Medium_titleMedium,
    titleSmall: AppTextStyles.ESC_Bold_titleSmall,
    bodyLarge: AppTextStyles.ESC_Regular_bodyLarge,
    bodyMedium: AppTextStyles.ESC_Regular_bodyMedium,
    labelLarge: AppTextStyles.ESC_Medium_labelLarge,
  ),
);
