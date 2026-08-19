import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_custom_tab_bar_widget.dart';

/*
  COMANDO PARA PROBAR:
  flutter run -t test/features/paramedico/presentation/incident_details/widgets/incident_custom_tab_bar_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IncidentCustomTabBarVisualTest(),
    ),
  );
}

class IncidentCustomTabBarVisualTest extends StatefulWidget {
  const IncidentCustomTabBarVisualTest({super.key});

  @override
  State<IncidentCustomTabBarVisualTest> createState() =>
      _IncidentCustomTabBarVisualTestState();
}

class _IncidentCustomTabBarVisualTestState
    extends State<IncidentCustomTabBarVisualTest> {
  IncidentTabType _activeTab = IncidentTabType.lista;

  @override
  Widget build(BuildContext context) {
    final data = IncidentTabSelectorData(
      activeTab: _activeTab,
      availableTabs: IncidentTabType.values,
      onTabChanged: (type) {
        setState(() => _activeTab = type);
      },
    );

    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Pestaña Activa: ${_activeTab.label}'),
              const SizedBox(height: 20),
              IncidentCustomTabBar(data: data),
            ],
          ),
        ),
      ),
    );
  }
}
