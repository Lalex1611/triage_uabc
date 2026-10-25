import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Colores del rol activo (Figma: "Campo" = paramédico, "Hospital" = médico)
///
/// Se registra una sola vez en `MaterialApp.theme` según la sesión (ver `main.dart`)
/// y los componentes lo leen con `context.triageRole`, así no reciben el rol
/// como parámetro. Un rol nuevo = una constante más aquí.
@immutable
class TriageRoleTheme extends ThemeExtension<TriageRoleTheme> {
  const TriageRoleTheme({
    required this.accent,
    required this.soft,
    required this.accentShadow,
  });

  /// Color principal del rol (banda del encabezado, botón primario, pestaña activa)
  final Color accent;

  /// Fondo tenue del rol (métricas, opción grande, insignias)
  final Color soft;

  /// Resplandor bajo los botones con [accent]
  final List<BoxShadow> accentShadow;

  static const paramedic = TriageRoleTheme(
    accent: TriageColors.paramedicAccent,
    soft: TriageColors.paramedicSoft,
    accentShadow: TriageShadows.paramedicButton,
  );

  static const hospital = TriageRoleTheme(
    accent: TriageColors.hospitalAccent,
    soft: TriageColors.hospitalSoft,
    accentShadow: TriageShadows.hospitalButton,
  );

  @override
  TriageRoleTheme copyWith({
    Color? accent,
    Color? soft,
    List<BoxShadow>? accentShadow,
  }) {
    return TriageRoleTheme(
      accent: accent ?? this.accent,
      soft: soft ?? this.soft,
      accentShadow: accentShadow ?? this.accentShadow,
    );
  }

  @override
  TriageRoleTheme lerp(TriageRoleTheme? other, double t) {
    if (other == null) return this;
    return TriageRoleTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      accentShadow: BoxShadow.lerpList(accentShadow, other.accentShadow, t)!,
    );
  }
}

extension TriageRoleThemeContext on BuildContext {
  /// Rol activo; sin tema registrado (p. ej. sandboxes visuales) usa el de campo
  TriageRoleTheme get triageRole =>
      Theme.of(this).extension<TriageRoleTheme>() ?? TriageRoleTheme.paramedic;
}
