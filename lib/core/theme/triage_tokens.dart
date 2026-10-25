import 'package:flutter/material.dart';

/// Tokens del rediseño (Figma "Componentes · TRIAGE")
///
/// Fuente única de colores, tipografía y sombras para los componentes nuevos.
/// Los nombres siguen las variables de Figma traducidas al inglés
/// (p. ej. `Texto/Secundario` → [TriageColors.textSecondary]).
/// [AppColors] y [AppTextStyles] se mantienen hasta migrar cada pantalla.
class TriageColors {
  TriageColors._();

  // Texto
  static const Color textPrimary = Color(0xFF121924);
  static const Color textSecondary = Color(0xFF4A5667);
  static const Color textTertiary = Color(0xFF8695A8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Fondo
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF1F5F9);
  static const Color sunken = Color(0xFFE6EBF1);
  static const Color inverse = Color(0xFF121924);

  // Borde
  static const Color borderSubtle = Color(0xFFE6EBF1);
  static const Color borderMedium = Color(0xFFD4DCE5);
  static const Color borderStrong = Color(0xFFB3BFCC);

  // Rol: Campo (paramédico) y Hospital (médico)
  static const Color paramedicAccent = Color(0xFFC30508);
  static const Color paramedicSoft = Color(0xFFFEF2F3);
  static const Color hospitalAccent = Color(0xFF1D71B8);
  static const Color hospitalSoft = Color(0xFFEFF6FC);

  // Señal
  static const Color success = Color(0xFF0F9D58);
  static const Color successBackground = Color(0xFFE6F6EC);
  static const Color danger = Color(0xFFC30508);
  static const Color dangerBackground = Color(0xFFFDECEC);
  static const Color warning = Color(0xFFD98300);
  static const Color warningBackground = Color(0xFFFDF2DF);
  static const Color info = Color(0xFF0A7EA4);
  static const Color infoBackground = Color(0xFFE4F4F9);

  // TRIAGE (Figma no define fondo para naranja ni azul)
  static const Color triageRed = Color(0xFFC30508);
  static const Color triageRedBackground = Color(0xFFFDECEF);
  static const Color triageOrange = Color(0xFFF2711C);
  static const Color triageYellow = Color(0xFFF5C518);
  static const Color triageYellowBackground = Color(0xFFFEF8DF);
  static const Color triageGreen = Color(0xFF16A34A);
  static const Color triageGreenBackground = Color(0xFFE8F7EE);
  static const Color triageBlue = Color(0xFF2563EB);
  static const Color triageBlack = Color(0xFF1F2430);
  static const Color triageBlackBackground = Color(0xFFE7E9ED);
}

/// Estilos de texto de Figma. Sin color: cada componente lo asigna con `copyWith`.
class TriageTextStyles {
  TriageTextStyles._();

  static const String fontFamily = 'Inter';

  /// Título/Medio
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.2,
  );

  /// Título/Chico
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    letterSpacing: -0.1,
  );

  /// Cuerpo/Medio
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
  );

  /// Cuerpo/Chico
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 19 / 13,
  );

  /// Etiqueta/Grande
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    letterSpacing: -0.1,
  );

  /// Etiqueta/Media
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
  );

  /// Etiqueta/Chica
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.4,
  );

  /// Dato/Grande
  static const TextStyle dataLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 28 / 24,
    letterSpacing: -0.6,
  );
}

/// Sombras de Figma (`Sombra`, `Sombra/Tarjeta`, `Sombra/Barra`, `Sombra/Flotante`)
class TriageShadows {
  TriageShadows._();

  static const List<BoxShadow> base = [
    BoxShadow(color: Color(0x260A121F), offset: Offset(0, 3), blurRadius: 3),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0A121F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x170A121F),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> bar = [
    BoxShadow(color: Color(0x0F0A121F), offset: Offset(0, -1)),
    BoxShadow(
      color: Color(0x140A121F),
      offset: Offset(0, -8),
      blurRadius: 24,
      spreadRadius: -8,
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1A0A121F),
      offset: Offset(0, 4),
      blurRadius: 10,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x290A121F),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -6,
    ),
  ];

  /// Resplandor de color bajo los botones con relleno
  static const List<BoxShadow> paramedicButton = [
    BoxShadow(color: Color(0x59C20508), offset: Offset(0, 3), blurRadius: 3),
  ];
  static const List<BoxShadow> hospitalButton = [
    BoxShadow(color: Color(0x401D71B8), offset: Offset(0, 3), blurRadius: 3),
  ];
  static const List<BoxShadow> successButton = [
    BoxShadow(color: Color(0x400F9D58), offset: Offset(0, 3), blurRadius: 3),
  ];
}
