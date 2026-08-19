import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/quick_patient_registration_launcher.dart';

class ParamedicoShellPage extends StatelessWidget {
  const ParamedicoShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onNavTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    if (index == 3) {
      QuickPatientRegistrationLauncher.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: navigationShell,
      bottomNavigationBar: ParamedicoNavbar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
