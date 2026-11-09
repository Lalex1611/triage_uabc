import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Tokens y helpers para adaptar layouts Figma a distintos tamaños de pantalla
///
/// [dim] es solo para medidas decorativas: nunca para zonas táctiles ni texto.
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

  /// Ancho que ocupa [text] en una línea, con el tamaño de texto del usuario
  static double textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  /// Escala horizontal suave (no agranda en tablets; solo reduce en pantallas chicas)
  static double scaleW(BuildContext context) {
    final w = sizeOf(context).width;
    return (w / designWidth).clamp(0.82, 1.0);
  }

  static double horizontalPadding(BuildContext context) {
    final w = sizeOf(context).width;
    if (w < 340) return TriageSpacing.md;
    if (w < compactWidth) return TriageSpacing.lg;
    return TriageSpacing.xxl;
  }

  /// Altura de la píldora de navegación con sus márgenes y la zona segura
  static double bottomNavExtent(BuildContext context) {
    return TriageSizes.controlLarge +
        2 * TriageSpacing.xs +
        TriageSpacing.sm +
        math.max(MediaQuery.paddingOf(context).bottom, TriageSpacing.sm);
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
