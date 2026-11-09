import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Pestañas segmentadas del rediseño (Figma "TRIAGE/Pestaña" dentro del
/// contenedor "Pestañas" de B07)
///
/// Si caben, se reparten el ancho a partes iguales; si no, en proporción a su
/// texto; y si tampoco (pantalla muy estrecha o texto grande), la fila se
/// desplaza. El texto nunca se reduce. Cada celda responde al toque en todo su alto (píldora + relleno
/// = 46), por encima del mínimo de 44.
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

  /// Ancho que necesita cada pestaña para mostrar su texto completo
  List<double> _cellWidths(BuildContext context) => [
    for (final label in labels)
      AppResponsive.textWidth(context, label, TriageTextStyles.labelMedium) +
          2 * TriageSpacing.sm +
          2 * TriageSpacing.xxs,
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TriageColors.sunken,
        borderRadius: BorderRadius.circular(TriageRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TriageSpacing.xxs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widths = _cellWidths(context);
            final total = widths.reduce((a, b) => a + b);
            if (total > constraints.maxWidth) {
              return _ScrollingTabs(
                labels: labels,
                selectedIndex: selectedIndex,
                onChanged: onChanged,
              );
            }
            final isEqual =
                widths.reduce(math.max) * labels.length <= constraints.maxWidth;
            return Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    flex: isEqual ? 1 : widths[i].ceil(),
                    child: _Tab(
                      label: labels[i],
                      selected: i == selectedIndex,
                      onTap: () => onChanged(i),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fila desplazable que mantiene a la vista la pestaña seleccionada
class _ScrollingTabs extends StatefulWidget {
  const _ScrollingTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<_ScrollingTabs> createState() => _ScrollingTabsState();
}

class _ScrollingTabsState extends State<_ScrollingTabs> {
  final _selectedKey = GlobalKey();

  void _revealSelected(Duration duration) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = _selectedKey.currentContext;
      if (selected == null || !selected.mounted) return;
      Scrollable.ensureVisible(selected, alignment: 0.5, duration: duration);
    });
  }

  @override
  void initState() {
    super.initState();
    _revealSelected(Duration.zero);
  }

  @override
  void didUpdateWidget(_ScrollingTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _revealSelected(kThemeAnimationDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < widget.labels.length; i++)
            _Tab(
              key: i == widget.selectedIndex ? _selectedKey : null,
              label: widget.labels[i],
              selected: i == widget.selectedIndex,
              onTap: () => widget.onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
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
          // El relleno queda dentro de la zona táctil: píldora + 2 × xs = 46
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TriageSpacing.xxs,
              vertical: TriageSpacing.xs,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: TriageSizes.pill),
              padding: const EdgeInsets.symmetric(horizontal: TriageSpacing.sm),
              decoration: selected
                  ? const BoxDecoration(
                      color: TriageColors.surface,
                      borderRadius: BorderRadius.all(
                        Radius.circular(TriageRadii.full),
                      ),
                      boxShadow: TriageShadows.subtle,
                    )
                  : null,
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  label,
                  softWrap: false,
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
    );
  }
}
