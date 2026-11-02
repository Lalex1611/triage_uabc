// Sandbox visual de la navegación inferior (ParamedicoNavbar, MedicoNavbar):
// flutter run -t test/shared/widgets/app_module_bottom_nav_visual_test.dart
import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() => runApp(const _NavSandbox());

class _NavSandbox extends StatefulWidget {
  const _NavSandbox();

  @override
  State<_NavSandbox> createState() => _NavSandboxState();
}

class _NavSandboxState extends State<_NavSandbox> {
  bool _hospital = false;
  bool _bigText = false;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(_bigText ? 2 : 1)),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: TriageColors.surface,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(TriageSpacing.lg),
            children: [
              SwitchListTile(
                title: const Text('Rol hospital'),
                value: _hospital,
                onChanged: (v) => setState(() {
                  _hospital = v;
                  _index = 0;
                }),
              ),
              SwitchListTile(
                title: const Text('Texto al 200 %'),
                value: _bigText,
                onChanged: (v) => setState(() => _bigText = v),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _hospital
            ? MedicoNavbar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
              )
            : ParamedicoNavbar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
              ),
      ),
    );
  }
}
