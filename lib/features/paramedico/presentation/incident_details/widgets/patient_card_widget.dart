import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/shared/widgets/patient_lifecycle_status_badge.dart';

// Tarjeta de paciente en la lista de Incident Details
class PatientCard extends StatelessWidget {
  final PatientCardData data;

  const PatientCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 77,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTriageBand(),
          Expanded(child: _buildCardContent()),
        ],
      ),
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
            /* FILA 1: Nombre, Botón Editar, Fecha */
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
                GestureDetector(
                  onTap: data.onEditTap,
                  child: SvgPicture.asset(
                    AppIcons.paramedicoIncidenteEdit,
                    width: 14,
                    height: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.dateStr,
                  style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                    fontSize: 7.92,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),

            /* FILA 2: Coordenadas, Ver mapa, Flecha (Chevron) */
            Row(
              children: [
                SvgPicture.asset(
                  AppIcons.paramedicoIncidenteLocation,
                  width: 10,
                  height: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  data.coordinates,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 8,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: data.onMapTap,
                  child: Text(
                    'Ver mapa',
                    style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                      fontSize: 8,
                      color: Colors.black.withValues(alpha: 0.45),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ],
            ),

            /* FILA 3: Label de Estado y Badge de Estado */
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
    return PatientLifecycleStatusBadge(status: data.status);
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
                topLeft: Radius.circular(13.2),
                bottomLeft: Radius.circular(13.2),
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
                        topRight: Radius.circular(13.2),
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
                      bottomLeft: Radius.circular(13.2),
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
