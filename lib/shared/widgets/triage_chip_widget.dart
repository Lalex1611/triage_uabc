import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Chip de filtro del rediseño (Figma "TRIAGE/Chip")
///
/// Seleccionado: fondo oscuro y texto blanco. No seleccionado: blanco con borde.
/// La píldora mide 38 de alto como Figma, pero la zona táctil llega a 44
/// (mínimo de accesibilidad). Para una fila de filtros, colocarlos en un
/// `ListView` horizontal o un `Wrap`.
class TriageChip extends StatelessWidget {
  const TriageChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const double _minTouchTarget = 44;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(
      side: selected
          ? BorderSide.none
          : const BorderSide(color: TriageColors.borderMedium, width: 1.25),
    );
    final foreground = selected
        ? TriageColors.textInverse
        : TriageColors.textSecondary;

    // MergeSemantics: el InkWell crea su propio nodo; sin unirlo, el lector
    // anunciaría el texto sin "botón" ni "seleccionado"
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        selected: selected,
        // El margen invisible alrededor de la píldora también responde al toque
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTouchTarget,
              minHeight: _minTouchTarget,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Material(
                color: selected ? TriageColors.inverse : TriageColors.surface,
                shape: shape,
                child: InkWell(
                  onTap: onTap,
                  customBorder: shape,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 38),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          label,
                          style: TriageTextStyles.labelMedium.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
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
