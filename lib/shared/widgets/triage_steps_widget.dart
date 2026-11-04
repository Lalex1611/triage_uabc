import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Progreso por pasos del rediseño (Figma "TRIAGE/Paso", traslado B14 y START
/// guiado)
///
/// Una barra por paso que reparte el ancho disponible: hechos en el color del
/// rol atenuado, [current] en el color del rol y pendientes en gris. [current]
/// empieza en 1. Las barras no son la única señal: el lector de pantalla anuncia
/// "Paso 1 de 3" y la pantalla lo acompaña con un texto (ver `TriageSheet`).
class TriageSteps extends StatelessWidget {
  const TriageSteps({super.key, required this.current, required this.total})
    : assert(total > 0),
      assert(current >= 1 && current <= total);

  final int current;
  final int total;

  static const _barHeight = 6.0;
  static const _doneOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final accent = context.triageRole.accent;

    return Semantics(
      container: true,
      label: 'Paso $current de $total',
      child: Row(
        spacing: TriageSpacing.xs,
        children: [
          for (var step = 1; step <= total; step++)
            Expanded(
              child: SizedBox(
                height: _barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: step < current
                        ? accent.withValues(alpha: _doneOpacity)
                        : step == current
                        ? accent
                        : TriageColors.borderMedium,
                    borderRadius: BorderRadius.circular(TriageRadii.full),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
