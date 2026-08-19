import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_status_data.dart';

class MedicoRegisterStatusDropdownWidget extends StatelessWidget {
  final MedicoRegisterStatusData data;

  const MedicoRegisterStatusDropdownWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.white;
    if (data.currentStatus == MedicoPatientStatus.enEspera ||
        data.currentStatus == MedicoPatientStatus.enCamino) {
      textColor = Colors.black;
    }

    if (!data.canEdit) {
      return _buildPill(textColor, withArrow: false);
    }

    return PopupMenuButton<MedicoPatientStatus>(
      offset: const Offset(0, 40),
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (status) {
        if (status.canBeSelectedByMedico) {
          data.onStatusChanged(status);
        }
      },
      itemBuilder: (context) => MedicoPatientStatus.values
          .where((status) => status.canBeSelectedByMedico)
          .map((status) {
            return PopupMenuItem<MedicoPatientStatus>(
              value: status,
              child: _buildMenuItem(status),
            );
          })
          .toList(),
      child: _buildPill(textColor, withArrow: true),
    );
  }

  Widget _buildPill(Color textColor, {required bool withArrow}) {
    String label = data.currentStatus.label.toUpperCase();
    if (data.currentStatus == MedicoPatientStatus.enCamino) {
      label = 'EN CAMINO';
    }
    if (data.currentStatus == MedicoPatientStatus.altaMedica) {
      label = 'ALTA';
    }

    Widget? trailing;
    if (withArrow) {
      trailing = Icon(Icons.keyboard_arrow_down, color: textColor, size: 20);
    }

    return Container(
      width: 130,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: data.currentStatus.color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              color: textColor,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildMenuItem(MedicoPatientStatus status) {
    Color labelColor = Colors.black;
    if (!status.canBeSelectedByMedico) {
      labelColor = AppColors.inactive;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        status.label,
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
          color: labelColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
