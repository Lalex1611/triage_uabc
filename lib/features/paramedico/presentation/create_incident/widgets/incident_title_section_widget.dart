import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';

// Título autogenerado del incidente (editable con ícono)
class IncidentTitleSection extends StatelessWidget {
  final String id;
  final String title;
  final String dateStr;
  final VoidCallback onEditTap;

  const IncidentTitleSection({
    super.key,
    required this.id,
    required this.title,
    required this.dateStr,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 7,
                child: Text(
                  dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                    fontSize: 30,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: GestureDetector(
                  onTap: onEditTap,
                  child: SvgPicture.asset(
                    AppIcons.paramedicoIncidenteEdit,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
