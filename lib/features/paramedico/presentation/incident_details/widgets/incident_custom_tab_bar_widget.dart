import 'package:flutter/material.dart';
//import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';

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
        color: const Color(0xFFEFEFF1), // Fondo gris suave del bloque
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
    final activeColor = Colors.black;
    const inactiveColor = Color(0xFF999A9D);

    Color currentColor = inactiveColor;
    if (isSelected) {
      currentColor = activeColor;
    }

    return GestureDetector(
      onTap: () => data.onTabChanged(type),
      child: Container(
        width: type.width,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
          //border: Border.all(color: currentColor, width: 0.31),
        ),
        alignment: Alignment.center,
        child: Text(
          type.label,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: currentColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
