import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';

// Grupo flotante de controles del mapa: zoom y ubicacion
class MapFloatingControls extends StatelessWidget {
  final VoidCallback onLocateMe;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final bool followActive;

  const MapFloatingControls({
    super.key,
    required this.onLocateMe,
    required this.onZoomIn,
    required this.onZoomOut,
    this.followActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder.withValues(alpha: 0.7),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapControlButton(
              icon: AppIcons.paramedicoMapaZoomIncrease,
              onTap: onZoomIn,
            ),
            const _DividerLine(),
            _MapControlButton(
              icon: AppIcons.paramedicoMapaZoomDecrease,
              onTap: onZoomOut,
            ),
            const _DividerLine(),
            _MapControlButton(
              icon: AppIcons.paramedicoMapaLocateRedirect,
              onTap: onLocateMe,
              highlighted: followActive,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final bool highlighted;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 42,
        height: 42,
        color: highlighted
            ? AppColors.primaryParamedico.withValues(alpha: 0.08)
            : Colors.white,
        alignment: Alignment.center,
        child: SvgPicture.asset(
          icon,
          width: 22,
          height: 22,
          colorFilter: highlighted
              ? const ColorFilter.mode(
                  AppColors.primaryParamedico,
                  BlendMode.srcIn,
                )
              : null,
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.cardBorder.withValues(alpha: 0.7),
    );
  }
}
