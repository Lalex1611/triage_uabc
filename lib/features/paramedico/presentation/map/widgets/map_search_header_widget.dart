import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Cabecera del mapa interactivo paramedico
class MapSearchHeaderWidget extends StatelessWidget {
  const MapSearchHeaderWidget({
    super.key,
    required this.searchController,
    required this.onBack,
    required this.onSignOut,
  });

  final TextEditingController searchController;
  final VoidCallback onBack;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final hintStyle = AppTextStyles.ESC_Regular_bodyMedium.copyWith(
      fontSize: 14,
      color: AppColors.searchHint,
    );

    return Container(
      color: AppColors.primaryParamedico,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: SvgPicture.asset(
                AppIcons.paramedicoHeaderArrowBack,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.inputBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.paramedicoHeaderSearch,
                      height: 18,
                      width: 18,
                      colorFilter: ColorFilter.mode(
                        AppColors.searchHint,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: hintStyle.copyWith(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Buscar incidentes',
                          hintStyle: hintStyle,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onSignOut,
              child: SvgPicture.asset(
                AppIcons.paramedicoHeaderProfile,
                width: 28,
                height: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
