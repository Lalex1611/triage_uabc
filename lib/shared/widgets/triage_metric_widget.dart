import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Métrica del rediseño (Figma "TRIAGE/Métrica"): número grande y etiqueta
///
/// Tonos de Figma:
/// - Neutro: constructor por defecto.
/// - Rojo, Amarillo, Verde, Negro: [TriageMetric.level].
/// - Campo / Hospital: [TriageMetric.role], toma el color del rol activo.
///
/// Ocupa el ancho que le den; para una fila de métricas, envolver cada una en
/// `Expanded`.
class TriageMetric extends StatelessWidget {
  const TriageMetric({super.key, required this.value, required this.label})
    : level = null,
      _role = false;

  /// Solo niveles con fondo en Figma: rojo, amarillo, verde y negro
  const TriageMetric.level(
    TriageLevel this.level, {
    super.key,
    required this.value,
    required this.label,
  }) : assert(level != TriageLevel.orange && level != TriageLevel.blue),
       _role = false;

  const TriageMetric.role({super.key, required this.value, required this.label})
    : level = null,
      _role = true;

  final String value;
  final String label;
  final TriageLevel? level;
  final bool _role;

  @override
  Widget build(BuildContext context) {
    final level = this.level;
    final role = context.triageRole;

    final (Color background, Color number) = switch (level) {
      _ when _role => (role.soft, role.accent),
      null => (TriageColors.sunken, TriageColors.textPrimary),
      // Amarillo y verde de Figma no llegan a 3:1 sobre su fondo
      TriageLevel.yellow => (level.background!, TriageColors.textPrimary),
      TriageLevel.green => (level.background!, TriageColors.successText),
      _ => (level.background!, level.color),
    };

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        // heightFactor 1: centra en vertical sin estirarse al alto disponible
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          heightFactor: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TriageTextStyles.dataLarge.copyWith(color: number),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TriageTextStyles.labelSmall.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
