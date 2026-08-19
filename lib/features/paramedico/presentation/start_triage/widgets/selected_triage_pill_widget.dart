import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/selected_triage_pill_data.dart';

class SelectedTriagePillWidget extends StatelessWidget {
  final SelectedTriagePillData data;

  const SelectedTriagePillWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112.0, // Exacto de Figma
        height: 33.0, // Exacto de Figma
        decoration: BoxDecoration(
          color: data.category.color,
          borderRadius: BorderRadius.circular(19.44), // Exacto de Figma
          border: Border.all(
            color: Colors.white,
            width: 0.5,
          ), // Stroke Inside 0.5
        ),
        alignment: Alignment.center,
        child: Text(
          data.category.label[0].toUpperCase() +
              data.category.label.substring(1).toLowerCase(),
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
