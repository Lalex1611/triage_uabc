import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Botón de acción del rediseño (Figma "TRIAGE/Botón")
///
/// - [TriageButtonVariant.primaryParamedic] para la operación de campo (rojo)
///   y [TriageButtonVariant.primaryHospital] para la operación médica (azul).
/// - Deshabilitado: `onPressed == null` → opacidad 40 % y sin sombra.
/// - Cargando: `isLoading` → spinner en lugar del texto, conserva el ancho y no responde a toques.
///
/// Se ajusta al contenido; para ocupar todo el ancho, envolver en
/// `SizedBox(width: double.infinity)`.
enum TriageButtonVariant {
  primaryParamedic,
  primaryHospital,
  secondary,
  subtle,
  danger,
  success,
}

enum TriageButtonSize { large, medium }

class TriageButton extends StatelessWidget {
  const TriageButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TriageButtonVariant.primaryParamedic,
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
    final radius = BorderRadius.circular(isLarge ? 16 : 13);

    final (
      Color? background,
      Color foreground,
      List<BoxShadow>? shadow,
    ) = switch (variant) {
      TriageButtonVariant.primaryParamedic => (
        TriageColors.paramedicAccent,
        TriageColors.textInverse,
        TriageShadows.paramedicButton,
      ),
      TriageButtonVariant.primaryHospital => (
        TriageColors.hospitalAccent,
        TriageColors.textInverse,
        TriageShadows.hospitalButton,
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
    final spinnerSize = isLarge ? 20.0 : 18.0;

    return Semantics(
      button: true,
      enabled: !isDisabled && !isLoading,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: variant == TriageButtonVariant.secondary
                ? Border.all(color: TriageColors.borderMedium, width: 1.25)
                : null,
            boxShadow: isDisabled ? null : shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: radius,
              splashColor: foreground.withValues(alpha: 0.12),
              highlightColor: foreground.withValues(alpha: 0.08),
              child: ConstrainedBox(
                // minHeight y no height fija: crece si el usuario agranda el texto
                constraints: BoxConstraints(minHeight: isLarge ? 54 : 44),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isLarge ? 22 : 18),
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
                              strokeWidth: 2,
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
