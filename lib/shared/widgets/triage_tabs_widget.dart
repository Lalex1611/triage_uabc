import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Pestañas segmentadas del rediseño (Figma "TRIAGE/Pestaña" dentro del
/// contenedor "Pestañas" de B07)
///
/// Las pestañas se reparten el ancho disponible a partes iguales; si una
/// etiqueta no cabe se reduce en vez de cortarse. Cada celda responde al toque
/// en todo su alto (46 con el relleno del contenedor), por encima del mínimo de 44.
class TriageTabs extends StatelessWidget {
  const TriageTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(labels.length > 1),
       assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TriageColors.sunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: _Tab(
                  label: labels[i],
                  selected: i == selectedIndex,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          // El relleno queda dentro de la zona táctil: 38 visibles + 8 = 46
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Container(
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: selected
                  ? const BoxDecoration(
                      color: TriageColors.surface,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A0A121F),
                          offset: Offset(0, 1),
                          blurRadius: 1.5,
                        ),
                      ],
                    )
                  : null,
              child: Center(
                heightFactor: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TriageTextStyles.labelMedium.copyWith(
                      color: selected
                          ? TriageColors.textPrimary
                          : TriageColors.textSecondary,
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
