import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_status_data.dart';

// Franja entre cabecera y contenido: «Creado por» (como incidente) + estado del paciente
class DetailsStatusStripWidget extends StatelessWidget {
  final DetailsStatusData data;
  final EdgeInsetsGeometry padding;

  const DetailsStatusStripWidget({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCreationInfo()),
          const SizedBox(width: 12),
          _buildStatusSelector(context),
        ],
      ),
    );
  }

  Widget _buildCreationInfo() {
    const textGrey = Color(0xFF999A9D);
    const fontSize = 10.84;

    final labelStyle = AppTextStyles.ESC_Medium_bodyMedium.copyWith(
      color: textGrey,
      fontSize: fontSize,
    );
    final valueStyle = AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
      color: textGrey,
      fontSize: fontSize,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Creado por:', style: labelStyle),
              Flexible(
                child: Text(
                  data.creatorName,
                  style: valueStyle,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hace:', style: labelStyle),
              Text(data.timeElapsed, style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<PatientStatus>(
        enabled: data.canEdit,
        offset: const Offset(0, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: const Color(0xFFF5F5F5),
        onSelected: data.onStatusChanged,
        itemBuilder: (context) {
          final custom = data.statusMenuEntries;
          if (custom != null && custom.isNotEmpty) {
            return custom;
          }
          return [
            _buildPopupItem(PatientStatus.registrado, 'Registrado'),
            _buildPopupItem(PatientStatus.enEspera, 'En espera'),
            _buildPopupItem(PatientStatus.trasladando, 'Trasladando'),
          ];
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: data.currentStatus.color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _statusLabel(data.currentStatus).toUpperCase(),
                style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
              if (data.canEdit) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: data.currentStatus == PatientStatus.enEspera
                      ? Colors.black87
                      : Colors.black,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<PatientStatus> _buildPopupItem(
    PatientStatus status,
    String label,
  ) {
    return PopupMenuItem<PatientStatus>(
      value: status,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(PatientStatus status) {
    switch (status) {
      case PatientStatus.enEspera:
        return 'En espera';
      case PatientStatus.registrado:
        return 'Registrado';
      case PatientStatus.trasladando:
        return 'Trasladando';
      case PatientStatus.alta:
        return 'Alta médica';
      default:
        return status.label;
    }
  }
}
