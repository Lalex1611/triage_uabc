import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Buscador del rediseño (Figma "TRIAGE/Buscador")
///
/// Misma interfaz que los buscadores actuales (`controller`, `onChanged`) para
/// migrarlos directo. Con texto muestra una ✕ que lo borra y llama a
/// `onChanged('')`. Sin [controller] usa uno interno.
class TriageSearchBar extends StatefulWidget {
  const TriageSearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  State<TriageSearchBar> createState() => _TriageSearchBarState();
}

class _TriageSearchBarState extends State<TriageSearchBar> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: TriageSizes.touchTarget),
      // A la derecha poco relleno: la zona táctil de la ✕ ya deja aire
      padding: const EdgeInsets.only(
        left: TriageSpacing.lg,
        right: TriageSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(TriageRadii.full),
        border: Border.all(
          color: TriageColors.borderSubtle,
          width: TriageSizes.stroke,
        ),
      ),
      child: Row(
        children: [
          const TriageIcon(
            TriageIcons.search,
            size: TriageSizes.icon,
            color: TriageColors.textTertiary,
          ),
          const SizedBox(width: TriageSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: TriageTextStyles.bodyMedium.copyWith(
                color: TriageColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                // Línea de 22 + 2 × md + borde ≥ 48
                contentPadding: const EdgeInsets.symmetric(
                  vertical: TriageSpacing.md,
                ),
                hintText: widget.hint,
                // Figma usa texto terciario (3.05:1); el secundario llega a 4.5:1
                hintStyle: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: TriageSpacing.md)
                : IconButton(
                    onPressed: _clear,
                    tooltip: 'Borrar búsqueda',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: TriageSizes.touchTargetCompact,
                      height: TriageSizes.touchTargetCompact,
                    ),
                    icon: const TriageIcon(
                      TriageIcons.close,
                      size: TriageSizes.iconSmall,
                      color: TriageColors.textTertiary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
