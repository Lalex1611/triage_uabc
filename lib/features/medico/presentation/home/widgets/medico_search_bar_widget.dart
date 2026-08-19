import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';

// Barra de búsqueda del Home del médico
class MedicoSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const MedicoSearchBar({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding + 11),
      child: Container(
        height: 51,
        padding: const EdgeInsets.symmetric(horizontal: 20.93),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1.31),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
                  fontSize: 20.93,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar pacientes',
                  hintStyle: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
                    color: const Color(0xFFB3B3B3),
                    fontSize: 20.93,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 10.46),
            SvgPicture.asset(
              AppIcons.paramedicoHomeSearch,
              width: 20.93,
              height: 20.93,
              colorFilter: const ColorFilter.mode(
                Color(0xFFD2D2D2),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
