import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_sorting_options.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_list_header_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_sort_options_widget.dart';

// Encabezado de la lista de pacientes en Home del médico
class MedicoPatientListHeader extends StatefulWidget {
  final MedicoPatientListHeaderData data;

  const MedicoPatientListHeader({super.key, required this.data});

  @override
  State<MedicoPatientListHeader> createState() =>
      _MedicoPatientListHeaderState();
}

class _MedicoPatientListHeaderState extends State<MedicoPatientListHeader> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  MedicoPatientSortOption _selectedSort = MedicoPatientSortOption.recent;

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
            child: MedicoSortOptions(
              selectedOption: _selectedSort,
              onOptionSelected: (option) {
                setState(() {
                  _selectedSort = option;
                });
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
      padding: const EdgeInsets.symmetric(horizontal: 35),
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
                width: 100,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.primaryMedico,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.cardBorder.withValues(alpha: 0.5),
                    width: 0.33,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedSort.shortLabel,
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
