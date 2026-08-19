import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';

// Cabecera superior específica para la vista de detalles
class IncidentDetailHeader extends StatelessWidget {
  final IncidentHeaderData data;

  const IncidentDetailHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryParamedico, // Rojo de cabecera de emergencia
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 39),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                flex: 4,
                fit: FlexFit.tight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 6,
                fit: FlexFit.tight,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    data.createdAtLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.1,
                  ),
                ),
              ),
              if (data.isEditable && data.onEditTitleTap != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: data.onEditTitleTap,
                  child: SvgPicture.asset(
                    AppIcons.paramedicoIncidenteEdit,
                    height: 24,
                    width: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'GPS capturado',
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SvgPicture.asset(
                AppIcons.paramedicoIncidenteLocation,
                height: 12,
                width: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  data.gpsCoordinates,
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.hasGps && data.onShowMapTap != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: data.onShowMapTap,
                  child: Text(
                    'Mostrar',
                    style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
              if (data.isEditable && data.onEditLocationTap != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: data.onEditLocationTap,
                  child: Text(
                    'Editar',
                    style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTriageSquare(data.redCount, AppColors.triagePre_rojo),
              _buildTriageSquare(
                data.yellowCount,
                AppColors.triagePre_amarillo,
              ),
              _buildTriageSquare(data.greenCount, AppColors.triagePre_verde),
              _buildTriageSquare(data.blackCount, AppColors.triagePre_negro),
              const Spacer(),
              _buildTotalPatients(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriageSquare(int count, Color color) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count.toString(),
        style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTotalPatients() {
    return Container(
      height: 24,
      constraints: const BoxConstraints(minWidth: 42),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppIcons.paramedicoIncidentePeopleQuantity,
            height: 15,
            width: 15,
          ),
          const SizedBox(width: 4),
          Text(
            data.totalPatients.toString(),
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              color: Colors.white,
              fontSize: 12,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
