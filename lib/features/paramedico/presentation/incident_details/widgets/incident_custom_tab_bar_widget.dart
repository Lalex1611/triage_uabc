import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Barra de pestañas personalizada para la vista de incidentes
class IncidentCustomTabBar extends StatelessWidget {
  final IncidentTabSelectorData data;

  const IncidentCustomTabBar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TriageColors.sunken,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: data.availableTabs.asMap().entries.map((entry) {
            final tab = entry.value;
            final isLast = entry.key == data.availableTabs.length - 1;

            double paddingRight = 4;
            if (isLast) {
              paddingRight = 0;
            }

            return Padding(
              padding: EdgeInsets.only(right: paddingRight),
              child: _buildTab(tab),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(IncidentTabType type) {
    final isSelected = data.activeTab == type;

    return GestureDetector(
      onTap: () => data.onTabChanged(type),
      child: Container(
        width: type.width,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? TriageColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected ? TriageShadows.card : null,
        ),
        alignment: Alignment.center,
        child: Text(
          type.label,
          style:
              (isSelected
                      ? TriageTextStyles.labelMedium
                      : TriageTextStyles.labelSmall)
                  .copyWith(
                    color: isSelected
                        ? TriageColors.textPrimary
                        : TriageColors.textSecondary,
                  ),
        ),
      ),
    );
  }
}
