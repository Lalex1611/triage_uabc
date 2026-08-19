import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// Fila que muestra coordenadas GPS con opciones de mostrar y editar
class CapturedGpsRowWidget extends StatelessWidget {
  final String coordinates;
  final String label;
  final VoidCallback onShowTap;
  final VoidCallback onEditTap;
  final bool lightOnDark;
  final String iconAssetPath;

  const CapturedGpsRowWidget({
    super.key,
    required this.coordinates,
    required this.onShowTap,
    required this.onEditTap,
    this.label = 'GPS capturado',
    this.lightOnDark = false,
    this.iconAssetPath = AppIcons.unicoPacienteLocationRojo,
  });

  @override
  Widget build(BuildContext context) {
    final primary = lightOnDark
        ? Colors.white
        : Colors.black.withValues(alpha: 0.45);
    final linkStyle =
        (lightOnDark
                ? AppTextStyles.ESC_Bold_titleSmall
                : AppTextStyles.ESC_Medium_bodyMedium)
            .copyWith(
              fontSize: lightOnDark ? 13 : 13.2,
              color: lightOnDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: lightOnDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              fontWeight: lightOnDark ? FontWeight.w700 : FontWeight.w500,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
            fontSize: lightOnDark ? 14 : 16.4,
            color: primary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            SvgPicture.asset(
              iconAssetPath,
              width: lightOnDark ? 15 : 16,
              height: lightOnDark ? 15 : 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                coordinates,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: lightOnDark ? 13 : 13.2,
                  color: primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onShowTap,
              child: Text('Mostrar', style: linkStyle),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEditTap,
              child: Text('Editar', style: linkStyle),
            ),
          ],
        ),
      ],
    );
  }
}
