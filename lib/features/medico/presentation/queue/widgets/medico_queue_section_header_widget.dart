import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_section_header_data.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_sorting_options.dart';

class MedicoQueueSectionHeaderWidget extends StatefulWidget {
  final MedicoQueueSectionHeaderData data;

  const MedicoQueueSectionHeaderWidget({super.key, required this.data});

  @override
  State<MedicoQueueSectionHeaderWidget> createState() =>
      _MedicoQueueSectionHeaderWidgetState();
}

class _MedicoQueueSectionHeaderWidgetState
    extends State<MedicoQueueSectionHeaderWidget> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _toggleMenu() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _removeMenu();
    }
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 148,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-48, 45), // Alineado a la derecha del botón azul
          child: Material(
            color: Colors.transparent,
            child: _MedicoSortMenu(
              selectedOption: widget.data.currentSort,
              onOptionSelected: (option) {
                widget.data.onSortTap(option);
                _removeMenu();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'En cola (${widget.data.total})',
            style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
              color: Colors.black,
              fontSize: 22,
            ),
          ),
          CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedico,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.data.currentSort.shortLabel,
                      style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.swap_vert, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicoSortMenu extends StatelessWidget {
  final MedicoPatientSortOption selectedOption;
  final Function(MedicoPatientSortOption) onOptionSelected;

  const _MedicoSortMenu({
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8B8B8B), width: 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: MedicoPatientSortOption.values.map(_buildOption).toList(),
      ),
    );
  }

  Widget _buildOption(MedicoPatientSortOption option) {
    final isSelected = selectedOption == option;
    return GestureDetector(
      onTap: () => onOptionSelected(option),
      child: Container(
        width: 148,
        height: 57.33,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: (() {
            Color sortOptionColor = Colors.transparent;
            if (isSelected) {
              sortOptionColor = const Color(0xFFF1EFEF);
            }
            return sortOptionColor;
          })(),
          borderRadius: _getBorderRadiusForOption(option),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          option.title,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: Colors.black,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadiusForOption(MedicoPatientSortOption option) {
    if (option == MedicoPatientSortOption.values.first) {
      return const BorderRadius.vertical(top: Radius.circular(15));
    } else if (option == MedicoPatientSortOption.values.last) {
      return const BorderRadius.vertical(bottom: Radius.circular(15));
    }
    return BorderRadius.zero;
  }
}
