import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 51,
        padding: const EdgeInsets.symmetric(horizontal: 20.93),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1.31),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              AppIcons.paramedicoHomeSearch,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFFB3B3B3),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 15,
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  hintText: 'Buscar paciente',
                  hintStyle: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
