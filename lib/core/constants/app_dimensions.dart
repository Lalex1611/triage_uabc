// / Dimensiones globales del sistema de diseño
class AppDimensions {
  AppDimensions._(); // clase no instanciable — solo constantes estáticas

  // ─── HEADER ────────────────────────────────────────────────────────────────
  /* / Altura fija de todas las variantes del AppHeader. */
  static const double headerHeight = 84.0;

  /* / Padding horizontal interno del header (no afecta al ancho total). */
  static const double headerPaddingH = 15.0;

  // / Separación mínima entre el borde inferior de íconos/botones
  static const double headerBottomClearance = 10.0;

  /* / Gap entre los 3 íconos de estado (wifi · notificación · perfil). */
  static const double headerStatusIconGap = 11.38;

  /* / Tamaño uniforme (alto = ancho) de cada ícono de estado. */
  static const double headerStatusIconSize = 32.0;

  // / Gap entre el arrow-back y el contenido central, y entre
  static const double headerNavGap = 14.0;

  /* / Gap entre el logo y el bloque título + subtítulo en la variante home. */
  static const double headerLogoTextGap = 12.0;

  /* / Tamaño del logo (alto = ancho) en la variante home. */
  static const double headerLogoSize = 52.0;

  /* / Gap fijo entre el texto "Regresar a…" y el action button en incident. */
  static const double headerActionGap = 8.0;
}
