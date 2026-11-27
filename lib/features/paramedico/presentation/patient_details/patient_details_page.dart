import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/patient_details_controller.dart';

// Cascarón de detalle de paciente (paramédico). Solo layout y datos inyectados
class PatientDetailsPage extends StatelessWidget {
  const PatientDetailsPage({
    super.key,
    required this.shellMode,
    this.errorMessage,
    this.appBar,
    this.stickyActionBar,
    required this.bodyChildren,
    this.bottomPadding = 24,
  });

  final PatientDetailsShellMode shellMode;
  final String? errorMessage;
  final PreferredSizeWidget? appBar;
  final Widget? stickyActionBar;
  final List<Widget> bodyChildren;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    switch (shellMode) {
      case PatientDetailsShellMode.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case PatientDetailsShellMode.error:
        return Scaffold(
          appBar: AppBar(title: const Text('Paciente')),
          body: Center(child: Text(errorMessage ?? 'Error')),
        );
      case PatientDetailsShellMode.notFound:
        return Scaffold(
          appBar: AppBar(title: const Text('Paciente')),
          body: const Center(child: Text('Paciente no encontrado.')),
        );
      case PatientDetailsShellMode.ready:
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: appBar,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...bodyChildren,
                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
              if (stickyActionBar != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: stickyActionBar,
                ),
            ],
          ),
        );
    }
  }
}
