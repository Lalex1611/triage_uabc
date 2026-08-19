import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_record_app_bar_data.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';

/// Encabezado de la vista de registro e información del paciente
class PatientRecordAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final PatientRecordAppBarData data;

  const PatientRecordAppBarWidget({super.key, required this.data});

  @override
  Size get preferredSize => const AppHeader(
        type: HeaderType.incident,
        color: Colors.transparent,
        isConnected: true,
        hasNotifications: false,
      ).preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      type: HeaderType.incident,
      color: paramedicoHeaderColor(data.triageCategory),
      isConnected: true,
      hasNotifications: false,
      backLabel: data.backLabel,
      actionLabel: data.actionLabel,
      onBack: data.onBackTap,
      onAction: data.onActionTap,
    );
  }
}
