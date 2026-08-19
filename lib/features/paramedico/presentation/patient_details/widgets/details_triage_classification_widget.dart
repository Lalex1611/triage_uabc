import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_triage_classification_data.dart';

class DetailsTriageClassificationWidget extends StatelessWidget {
  final DetailsTriageClassificationData data;

  const DetailsTriageClassificationWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = [
      TriageCategory.rojo,
      TriageCategory.amarillo,
      TriageCategory.verde,
      TriageCategory.negro,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clasificación START',
                style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              if (data.canEdit && !data.isEditingMode)
                GestureDetector(
                  onTap: data.onEditTap,
                  child: SvgPicture.asset(
                    AppIcons.paramedicoIncidenteEdit,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF999A9D),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 65),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCE1125), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categories.map((category) {
                final isSelected = data.selectedCategory == category;

                BorderRadius borderRadius = BorderRadius.circular(4.5);
                if (category == TriageCategory.rojo) {
                  borderRadius = const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    topRight: Radius.circular(4.5),
                    bottomRight: Radius.circular(4.5),
                  );
                } else if (category == TriageCategory.negro) {
                  borderRadius = const BorderRadius.only(
                    topLeft: Radius.circular(4.5),
                    bottomLeft: Radius.circular(4.5),
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  );
                }

                return GestureDetector(
                  onTap: (() {
                    VoidCallback? tapAction;
                    if (data.canEdit && data.isEditingMode) {
                      tapAction = () => data.onCategorySelected(category);
                    }
                    return tapAction;
                  })(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 63,
                    height: 63,
                    decoration: BoxDecoration(
                      color: (() {
                        Color classificationColor = category.color.withValues(
                          alpha: 0.5,
                        );
                        if (isSelected) {
                          classificationColor = category.color;
                        }
                        return classificationColor;
                      })(),
                      borderRadius: borderRadius,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
