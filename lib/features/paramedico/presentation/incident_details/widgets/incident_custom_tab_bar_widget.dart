import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Adapta las pestañas del incidente a [TriageTabs]
class IncidentCustomTabBar extends StatelessWidget {
  final IncidentTabSelectorData data;

  const IncidentCustomTabBar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tabs = data.availableTabs;
    final gutter = context.horizontalPadding;

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, TriageSpacing.md),
      child: TriageTabs(
        labels: [for (final tab in tabs) tab.label],
        selectedIndex: tabs.indexOf(data.activeTab),
        onChanged: (index) => data.onTabChanged(tabs[index]),
      ),
    );
  }
}
