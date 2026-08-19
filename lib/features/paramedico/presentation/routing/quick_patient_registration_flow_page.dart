import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/paramedico_quick_patient_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/quick_patient_registration_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/quick_patient_registration_launcher.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_session_actions.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';

/// Controlador y vista para el registro rápido de pacientes
class QuickPatientRegistrationFlowPage extends StatefulWidget {
  const QuickPatientRegistrationFlowPage({super.key});

  @override
  State<QuickPatientRegistrationFlowPage> createState() =>
      _QuickPatientRegistrationFlowPageState();
}

class _QuickPatientRegistrationFlowPageState
    extends State<QuickPatientRegistrationFlowPage> {
  late final QuickPatientRegistrationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuickPatientRegistrationController();
    _controller.addListener(_onController);
    QuickPatientRegistrationLauncher.register(_launch);
    unawaited(_controller.refreshNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
  }

  @override
  void dispose() {
    QuickPatientRegistrationLauncher.unregister();
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  void _launch() {
    if (!mounted) return;
    unawaited(_controller.launchRegistration(context));
  }

  @override
  Widget build(BuildContext context) {
    return ParamedicoQuickPatientPage(
      header: AppHeader(
        type: HeaderType.home,
        color: AppColors.primaryParamedico,
        isConnected: true,
        hasNotifications: _controller.unreadNotifications > 0,
        subtitle: 'Registro de paciente',
        onNotificationTap: () => _controller.openNotifications(context),
        onProfileTap: () => ParamedicoSessionActions.openProfileSheet(context),
      ),
      phase: _controller.phase,
      errorMessage: _controller.errorMessage,
      onLaunchTap: _launch,
    );
  }
}
