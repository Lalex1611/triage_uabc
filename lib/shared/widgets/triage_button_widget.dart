import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Botón de acción del rediseño (Figma "TRIAGE/Botón")
///
/// - [TriageButtonVariant.primary] toma el color del rol activo
///   ([TriageRoleTheme]): rojo en campo, azul en hospital.
/// - Deshabilitado: `onPressed == null` → opacidad 40 % y sin sombra.
/// - Cargando: `isLoading` → spinner en lugar del texto, conserva el ancho y no responde a toques.
///
/// Se ajusta al contenido; para ocupar todo el ancho, envolver en
/// `SizedBox(width: double.infinity)`.
enum TriageButtonVariant { primary, secondary, subtle, danger, success }

enum TriageButtonSize { large, medium }

class TriageButton extends StatelessWidget {
  const TriageButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TriageButtonVariant.primary,
    this.size = TriageButtonSize.large,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final TriageButtonVariant variant;
  final TriageButtonSize size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isLarge = size == TriageButtonSize.large;
    final isDisabled = onPressed == null && !isLoading;
    final radius = BorderRadius.circular(
      isLarge ? TriageRadii.lg : TriageRadii.md,
    );

    final (
      Color? background,
      Color foreground,
      List<BoxShadow>? shadow,
    ) = switch (variant) {
      TriageButtonVariant.primary => (
        context.triageRole.accent,
        TriageColors.textInverse,
        context.triageRole.accentShadow,
      ),
      TriageButtonVariant.secondary => (
        TriageColors.surface,
        TriageColors.textPrimary,
        TriageShadows.base,
      ),
      TriageButtonVariant.subtle => (null, TriageColors.textSecondary, null),
      TriageButtonVariant.danger => (
        TriageColors.danger,
        TriageColors.textInverse,
        TriageShadows.paramedicButton,
      ),
      TriageButtonVariant.success => (
        TriageColors.success,
        TriageColors.textInverse,
        TriageShadows.successButton,
      ),
    };

    final textStyle =
        (isLarge ? TriageTextStyles.labelLarge : TriageTextStyles.labelMedium)
            .copyWith(color: foreground);
    final spinnerSize = isLarge ? TriageSizes.icon : TriageSizes.iconSmall;

    return Semantics(
      button: true,
      enabled: !isDisabled && !isLoading,
      child: Opacity(
        opacity: isDisabled ? TriageOpacity.disabled : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: variant == TriageButtonVariant.secondary
                ? Border.all(
                    color: TriageColors.borderMedium,
                    width: TriageSizes.stroke,
                  )
                : null,
            boxShadow: isDisabled ? null : shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: radius,
              splashColor: foreground.withValues(alpha: TriageOpacity.pressed),
              highlightColor: foreground.withValues(alpha: TriageOpacity.hover),
              child: ConstrainedBox(
                // Mínimos y no medidas fijas: crece si el usuario agranda el
                // texto y una etiqueta corta no baja de la zona táctil
                constraints: BoxConstraints(
                  minWidth: isLarge
                      ? TriageSizes.touchTarget
                      : TriageSizes.touchTargetCompact,
                  minHeight: isLarge
                      ? TriageSizes.controlLarge
                      : TriageSizes.touchTargetCompact,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLarge ? TriageSpacing.xl : TriageSpacing.lg,
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: isLoading ? 0 : 1,
                          child: Text(
                            label,
                            style: textStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (isLoading)
                          SizedBox.square(
                            dimension: spinnerSize,
                            child: CircularProgressIndicator(
                              strokeWidth: TriageSizes.strokeStrong,
                              color: foreground,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
