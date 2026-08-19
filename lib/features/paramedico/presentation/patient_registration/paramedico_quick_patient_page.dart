import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/quick_patient_registration_controller.dart';

/// Cascarón del tab Paciente (estado idle/error mientras se abre el formulario)
class ParamedicoQuickPatientPage extends StatelessWidget {
  const ParamedicoQuickPatientPage({
    super.key,
    required this.header,
    required this.phase,
    this.errorMessage,
    required this.onLaunchTap,
  });

  final PreferredSizeWidget header;
  final QuickPatientRegistrationPhase phase;
  final String? errorMessage;
  final VoidCallback onLaunchTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: header,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (phase) {
      case QuickPatientRegistrationPhase.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primaryParamedico, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'No se pudo iniciar el registro.',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onLaunchTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryParamedico,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        );
      case QuickPatientRegistrationPhase.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_alt_1, color: AppColors.primaryParamedico, size: 56),
            const SizedBox(height: 16),
            Text(
              'Registro rápido de paciente',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onLaunchTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryParamedico,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Registrar paciente'),
            ),
          ],
        );
    }
  }
}
