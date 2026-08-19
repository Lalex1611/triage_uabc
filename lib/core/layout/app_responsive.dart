import 'package:flutter/material.dart';

/// Tokens y helpers para adaptar layouts Figma a distintos tamaños de pantalla
class AppResponsive {
  AppResponsive._();

  /// Ancho de referencia del diseño (iPhone ~393 logical px)
  static const double designWidth = 393;

  /// Por debajo de este ancho se considera pantalla compacta (p. ej. Galaxy S24)
  static const double compactWidth = 360;

  /// Por debajo de esta altura el header fijo + lista suele desbordar en vertical
  static const double shortHeight = 720;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isCompactWidth(BuildContext context) =>
      sizeOf(context).width < compactWidth;

  static bool isShortScreen(BuildContext context) =>
      sizeOf(context).height < shortHeight;

  /// Escala horizontal suave (no agranda en tablets; solo reduce en pantallas chicas)
  static double scaleW(BuildContext context) {
    final w = sizeOf(context).width;
    return (w / designWidth).clamp(0.82, 1.0);
  }

  static double horizontalPadding(BuildContext context) {
    final w = sizeOf(context).width;
    if (w < 340) return 12;
    if (w < compactWidth) return 16;
    return 24;
  }

  /// Altura útil de la barra inferior (iconos + safe area del sistema)
  static double bottomNavExtent(BuildContext context) {
    return kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom;
  }

  /// Escala un valor de diseño Figma al ancho actual
  static double dim(BuildContext context, double designValue) =>
      designValue * scaleW(context);
}

extension AppResponsiveContext on BuildContext {
  bool get isCompactWidth => AppResponsive.isCompactWidth(this);

  bool get isShortScreen => AppResponsive.isShortScreen(this);

  double get horizontalPadding => AppResponsive.horizontalPadding(this);

  double get bottomNavExtent => AppResponsive.bottomNavExtent(this);

  double rDim(double designValue) => AppResponsive.dim(this, designValue);
}
