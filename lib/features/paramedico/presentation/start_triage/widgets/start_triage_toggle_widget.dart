import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_toggle_data.dart';

class StartTriageToggleWidget extends StatelessWidget {
  final StartTriageToggleData data;

  const StartTriageToggleWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
      ), // Padding de 30 para acortar
      child: Container(
        decoration: BoxDecoration(
          color: const Color(
            0xFF1E1E1E,
          ), // Ojo: los grises aún no están en app_colors
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: StartTriageTabOption.values.map((tab) {
            final isActive = data.activeTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => data.onTabChanged(tab),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryParamedico
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14.26),
                    border: isActive
                        ? Border.all(
                            color: AppColors.primaryParamedico,
                            width: 0.8,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label,
                    style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                      color: (() {
                        Color toggleColor = const Color(0xFF868A95);
                        if (isActive) {
                          toggleColor = Colors.white;
                        }
                        return toggleColor;
                      })(),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
