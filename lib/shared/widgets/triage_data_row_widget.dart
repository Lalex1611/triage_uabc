import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Fila de dato del rediseño (Figma "TRIAGE/Fila de dato"): concepto a la
/// izquierda y valor a la derecha
///
/// Variantes de Figma:
/// - Valor: con [value].
/// - Flecha: con [onTap]; toda la fila responde al toque y muestra un chevron.
/// - Nada: sin [value] ni [onTap].
///
/// Si concepto y valor no caben en una línea (texto grande o valor largo), el
/// valor baja a la siguiente. Las filas no traen separador: lo pone la pantalla.
class TriageDataRow extends StatelessWidget {
  const TriageDataRow({super.key, required this.label, this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final trailing = [
      if (value != null)
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TriageTextStyles.labelMedium.copyWith(
              color: TriageColors.textPrimary,
            ),
          ),
        ),
      if (onTap != null) ...[
        if (value != null) const SizedBox(width: TriageSpacing.sm),
        const TriageIcon(
          TriageIcons.chevronRight,
          size: TriageSizes.iconSmall,
          color: TriageColors.textTertiary,
        ),
      ],
    ];

    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: onTap == null ? 0 : TriageSizes.touchTarget,
      ),
      // heightFactor 1: centra en vertical dentro del mínimo sin estirarse
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TriageSpacing.md),
          // Ancho completo para que spaceBetween lleve el valor a la derecha
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: TriageSpacing.md,
              runSpacing: TriageSpacing.xs,
              children: [
                Text(
                  label,
                  style: TriageTextStyles.bodyMedium.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                ),
                if (trailing.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: trailing),
              ],
            ),
          ),
        ),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: onTap == null
            ? row
            : Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap, child: row),
              ),
      ),
    );
  }
}
