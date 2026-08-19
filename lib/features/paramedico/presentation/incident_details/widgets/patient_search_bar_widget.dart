import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Barra de búsqueda para filtrar pacientes dentro del incidente activo
class PatientSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const PatientSearchBar({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromARGB(255, 116, 92, 92).withValues(alpha: 0.2),
          width: .4,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar pacientes',
                hintStyle: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
                  color: AppColors.searchHint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 15),
          SvgPicture.asset(
            AppIcons.paramedicoIncidenteSearch,
            width: 20.93,
            height: 20.93,
          ),
        ],
      ),
    );
  }
}
