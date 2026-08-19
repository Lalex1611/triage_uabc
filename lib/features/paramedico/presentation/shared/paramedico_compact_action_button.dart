import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// Botón compacto rojo reutilizable para acciones paramédicas
class ParamedicoCompactActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final String? iconAssetPath;
  final double scale;
  final bool forceLowercase;

  const ParamedicoCompactActionButton({
    super.key,
    required this.label,
    this.onTap,
    this.width,
    this.height = 40,
    this.iconAssetPath,
    this.scale = 1,
    this.forceLowercase = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final s = scale;
    final effectiveHeight = height * s;
    final fontSize = 14 * s;
    final iconSize = 16 * s;
    final horizontalPadding = 10 * s;
    final radius = 12 * s;
    final labelText = forceLowercase ? label.toLowerCase() : label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width != null ? width! * s : null,
        height: effectiveHeight,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFCE1125) : const Color(0xFFCCCCCC),
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (iconAssetPath != null) ...[
              SizedBox(width: 5 * s),
              SvgPicture.asset(
                iconAssetPath!,
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
