import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_triage_classification_data.dart';

class PatientTriageClassificationWidget extends StatelessWidget {
  final PatientTriageClassificationData data;

  const PatientTriageClassificationWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = [
      TriageCategory.rojo,
      TriageCategory.amarillo,
      TriageCategory.verde,
      TriageCategory.negro,
    ];

    final outerPad = context.isCompactWidth ? 16.0 : 65.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            data.sectionTitle,
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 15,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPad),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFCE1125),
                width: 1.5,
              ),
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

                final swatchColor = data.dimUnselectedColors && !isSelected
                    ? category.color.withValues(alpha: 0.5)
                    : category.color;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onTap: data.dimUnselectedColors
                            ? null
                            : () => data.onCategorySelected(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: swatchColor,
                            borderRadius: borderRadius,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (data.onStartTriageTap != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: outerPad),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: data.onStartTriageTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Protocolo Guiado START',
                    style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
