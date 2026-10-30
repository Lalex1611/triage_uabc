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
      constraints: const BoxConstraints(minHeight: 48),
      // 16 a la izquierda como Figma; a la derecha 2 + la zona de 44 de la ✕
      padding: const EdgeInsets.only(left: 16, right: 2),
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TriageColors.borderSubtle, width: 1.25),
      ),
      child: Row(
        children: [
          const TriageIcon(
            TriageIcons.search,
            size: 20,
            color: TriageColors.textTertiary,
          ),
          const SizedBox(width: 10),
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
                // 22 de línea + 22 + borde 2.5 = 46.5; el mínimo de 48 completa
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                hintText: widget.hint,
                hintStyle: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textTertiary,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: 14)
                : IconButton(
                    onPressed: _clear,
                    tooltip: 'Borrar búsqueda',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const TriageIcon(
                      TriageIcons.close,
                      size: 18,
                      color: TriageColors.textTertiary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
