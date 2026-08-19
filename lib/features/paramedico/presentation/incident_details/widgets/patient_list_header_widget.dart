import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/patient_sort_options_widget.dart';

// Encabezado de la lista de pacientes del incidente activo
class PatientListHeader extends StatefulWidget {
  final PatientListHeaderData data;

  const PatientListHeader({super.key, required this.data});

  @override
  State<PatientListHeader> createState() => _PatientListHeaderState();
}

class _PatientListHeaderState extends State<PatientListHeader> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  PatientSortOption get _selectedSort => widget.data.sortOption;

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
          offset: const Offset(-65, 35),
          child: Material(
            color: Colors.transparent,
            child: PatientSortOptions(
              selectedOption: _selectedSort,
              onOptionSelected: (option) {
                widget.data.onSortChanged(option);
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pacientes (${widget.data.patientCount})',
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: 83,
                height: 29.05,
                padding: const EdgeInsets.all(4.29),
                decoration: BoxDecoration(
                  color: AppColors.primaryParamedico,
                  borderRadius: BorderRadius.circular(12.45),
                  border: Border.all(
                    color: const Color(0xFFCECCCC).withValues(alpha: 0.5),
                    width: 0.27,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.data.sortOption.shortLabel,
                      style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4.29),
                    SvgPicture.asset(
                      AppIcons.paramedicoIncidenteSorting,
                      width: 14,
                      height: 14,
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
