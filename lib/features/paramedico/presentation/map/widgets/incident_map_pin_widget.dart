import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';

// Pin de incidente sobre el mapa interactivo
class IncidentMapPin extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const IncidentMapPin({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = selected ? 52.0 : 44.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryParamedico.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.primaryParamedico,
                    width: 1.5,
                  ),
                ),
              ),
            SvgPicture.asset(
              AppIcons.paramedicoMapaLocationIncident,
              width: size * 0.72,
              height: size * 0.72,
            ),
          ],
        ),
      ),
    );
  }
}
