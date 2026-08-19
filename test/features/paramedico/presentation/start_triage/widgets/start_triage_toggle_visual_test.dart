import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_toggle_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_toggle_widget.dart';

/*
  COMANDO PARA PROBAR ESTE WIDGET AISLADO:
  flutter run -t test/features/paramedico/presentation/start_triage/widgets/start_triage_toggle_visual_test.dart
*/

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartTriageToggleSandbox(),
    ),
  );
}

class StartTriageToggleSandbox extends StatefulWidget {
  const StartTriageToggleSandbox({super.key});

  @override
  State<StartTriageToggleSandbox> createState() =>
      _StartTriageToggleSandboxState();
}

class _StartTriageToggleSandboxState extends State<StartTriageToggleSandbox> {
  StartTriageTabOption _activeTab = StartTriageTabOption.asignacionRapida;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: Colors.black, // Fondo negro puro
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StartTriageToggleWidget(
                data: StartTriageToggleData(
                  activeTab: _activeTab,
                  onTabChanged: (tab) => setState(() => _activeTab = tab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
