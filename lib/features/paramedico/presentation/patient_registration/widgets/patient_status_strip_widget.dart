import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_status_data.dart';

class PatientStatusStripWidget extends StatelessWidget {
  final PatientStatusData data;

  const PatientStatusStripWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 340;

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCreationInfo(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildStatusSelector(context),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: _buildCreationInfo()),
              const SizedBox(width: 8),
              _buildStatusSelector(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreationInfo() {
    const textGrey = Color(0xFF999A9D);
    final labelStyle = AppTextStyles.ESC_Medium_bodyMedium.copyWith(
      color: textGrey,
      fontSize: 10,
    );
    final valueStyle = AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
      color: textGrey,
      fontSize: 10,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Creado por: ', style: labelStyle),
              Flexible(
                child: Text(
                  data.creatorName,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text('Hace: ', style: labelStyle),
              Flexible(
                child: Text(
                  data.timeElapsed,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
        itemBuilder: (context) => [
          _buildPopupItem(PatientStatus.enEspera, 'En espera'),
          _buildPopupItem(PatientStatus.trasladando, 'Trasladando'),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              Flexible(
                child: Text(
                  _getStatusLabel(data.currentStatus).toUpperCase(),
                  style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                    fontSize: 11,
                    color: data.currentStatus == PatientStatus.alta
                        ? Colors.black
                        : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.canEdit) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 18,
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

  String _getStatusLabel(PatientStatus status) {
    switch (status) {
      case PatientStatus.enEspera:
        return 'En espera';
      case PatientStatus.trasladando:
        return 'Trasladando';
      case PatientStatus.alta:
        return 'Alta médica';
      default:
        return status.label;
    }
  }
}
