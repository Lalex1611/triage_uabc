import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/shared/widgets/patient_lifecycle_status_badge.dart';

/// Tarjeta del incidente en el Home del médico (solo el panel superior)
/// Para traslado en curso, los botones van en [MedicoPatientIncomingTransferShell]
class MedicoPatientCard extends StatelessWidget {
  final MedicoPatientCardData data;

  /// Sin marco propio: va dentro de otro contenedor (p. eje. shell con botones debajo)
  final bool panelOnly;

  const MedicoPatientCard({
    super.key,
    required this.data,
    this.panelOnly = false,
  });

  static const double _radius = 13.2;

  @override
  Widget build(BuildContext context) {
    final panel = SizedBox(
      height: 77,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTriageBand(),
          Expanded(child: _buildCardContent()),
        ],
      ),
    );

    final note = data.footerNote;
    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        panel,
        if (note != null && note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 8,
                color: Colors.black54,
                height: 1.25,
              ),
            ),
          ),
      ],
    );

    if (panelOnly) {
      return inner;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: inner,
    );
  }

  Widget _buildCardContent() {
    return GestureDetector(
      onTap: data.onCardTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 15, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /* FILA 1: Nombre y Fecha */
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ESC_ExtraBold_titleLarge.copyWith(
                      fontSize: 10,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    data.dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                      fontSize: 7.92,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),

            /* FILA 2: Coordenadas, ETA, Ambulancia */
            Row(
              children: [
                SvgPicture.asset(
                  AppIcons.paramedicoIncidenteLocation,
                  width: 10,
                  height: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: Text(
                    data.coordinates,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                      fontSize: 8,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    data.eta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                      fontSize: 8,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SvgPicture.asset(
                  AppIcons.medicoHomeAmbulance,
                  width: 12,
                  height: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Text(
                    data.ambulanceUnit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                      fontSize: 8,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ],
            ),

            // FILA 3: Estado
            Row(
              children: [
                Text(
                  'ESTADO:',
                  style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                    fontSize: 10,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Flexible(child: _buildStatusBadge()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return PatientLifecycleStatusBadge(
      status: data.status,
      isRejected: data.isRejectedTransfer,
    );
  }

  Widget _buildTriageBand() {
    return SizedBox(
      width: 62,
      height: 77,
      child: Stack(
        children: [
          Container(
            width: 62,
            height: 77,
            decoration: BoxDecoration(
              color: data.triageCategory.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(MedicoPatientCard._radius),
                bottomLeft: Radius.circular(MedicoPatientCard._radius),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Column(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Container(
                    width: 60,
                    height: 21,
                    decoration: BoxDecoration(
                      color: data.triageCategory.color,
                      border: Border.all(color: Colors.white, width: 0.2),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(MedicoPatientCard._radius),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      data.id,
                      style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 21,
                  height: 17,
                  decoration: BoxDecoration(
                    color: data.triageCategory.color,
                    border: Border.all(color: Colors.white, width: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(MedicoPatientCard._radius),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.number.toString(),
                        maxLines: 1,
                        style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
