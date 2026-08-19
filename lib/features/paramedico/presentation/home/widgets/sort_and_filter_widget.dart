import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/incident_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/sort_button_widget.dart';

// Fila de controles integrados que contiene contadores, búsqueda y ordenamiento
class SortAndFilter extends StatefulWidget {
  final int totalIncidents;

  /// Si no es null, el padre controla «solo míos» y recibe cambios
  final bool? mineOnly;
  final ValueChanged<bool>? onMineOnlyChanged;

  /// Si no es null, el padre controla el criterio de orden
  final IncidentSortOption? sortOption;
  final ValueChanged<IncidentSortOption>? onSortChanged;

  const SortAndFilter({
    super.key,
    required this.totalIncidents,
    this.mineOnly,
    this.onMineOnlyChanged,
    this.sortOption,
    this.onSortChanged,
  });

  @override
  State<SortAndFilter> createState() => _SortAndFilterState();
}

class _SortAndFilterState extends State<SortAndFilter> {
  bool isShowingAll = true;
  IncidentSortOption selectedSort = IncidentSortOption.recent;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  bool get _externalMine =>
      widget.mineOnly != null && widget.onMineOnlyChanged != null;
  bool get _externalSort =>
      widget.sortOption != null && widget.onSortChanged != null;

  bool get _isShowingAll => _externalMine ? !widget.mineOnly! : isShowingAll;

  IncidentSortOption get _effectiveSort =>
      _externalSort ? widget.sortOption! : selectedSort;

  String _getShortText(IncidentSortOption option) {
    return option.shortLabel;
  }

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
          offset: const Offset(-48, 45), // Alineado a la derecha del botón rojo
          child: Material(
            color: Colors.transparent,
            child: SortMenu(
              selectedOption: _effectiveSort,
              onOptionSelected: (option) {
                if (_externalSort) {
                  widget.onSortChanged?.call(option);
                } else {
                  setState(() => selectedSort = option);
                }
                _removeMenu();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isActive) {
    final color = isActive
        ? const Color(0xFFCE1125).withValues(alpha: 0.8)
        : const Color(0xFFBDBDBD);
    return GestureDetector(
      onTap: () {
        final toMine = text == 'MÍOS';
        if (_externalMine) {
          widget.onMineOnlyChanged?.call(toMine);
        } else {
          setState(() {
            isShowingAll = !toMine;
          });
        }
      },
      child: Container(
        width: 68,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color, width: 0.4),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: color,
              fontSize: 7.65,
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
    final showTodos = _isShowingAll;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding + 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Incidentes activos ( ${widget.totalIncidents} )',
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterButton('TODOS', showTodos),
                    const SizedBox(width: 10.2),
                    _buildFilterButton('MÍOS', !showTodos),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: 100,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFCE1125),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFCECCCC).withValues(alpha: 0.5),
                    width: 0.33,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getShortText(_effectiveSort),
                      style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 5.17),
                    SvgPicture.asset(
                      AppIcons.paramedicoHomeSorting,
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
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
