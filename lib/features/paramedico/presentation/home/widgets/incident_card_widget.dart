import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import '../../../domain/entities/home/incident_for_cards.dart';

// Tarjeta individual que resume la información crítica de un incidente activo
class IncidentCard extends StatelessWidget {
  final IncidentForCards incident;
  final VoidCallback? onTap;

  const IncidentCard({super.key, required this.incident, this.onTap});

  Widget _buildTriageItem(Color color, int count) {
    return Container(
      width: 24.5,
      height: 25,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Contenedor principal con estilo de tarjeta, sombras suaves y bordes redondeados
    final radius = BorderRadius.circular(15);
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFCECCCC), width: 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con ID del incidente y estampa de tiempo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                incident.id,
                style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                  fontSize: 9,
                ),
              ),
              Text(
                incident.dateTime.toString().substring(0, 16),
                style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3.6),
          Text(
            incident.name_card,
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3.6),
          // Sección de geolocalización con coordenadas y enlace a mapa
          Row(
            children: [
              SvgPicture.asset(AppIcons.paramedicoHomeLocation),
              const SizedBox(width: 1.5),
              Text(
                '${incident.latitude}, ${incident.longitude}',
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 9,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 2.5),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Ver mapa',
                  style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                    color: Colors.black.withValues(alpha: 0.45),
                    fontSize: 9,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15.6),
          // Resumen de víctimas clasificadas por color de triage y conteo total
          Row(
            children: [
              _buildTriageItem(AppColors.triagePre_rojo, incident.red),
              const SizedBox(width: 8.6),
              _buildTriageItem(AppColors.triagePre_amarillo, incident.yellow),
              const SizedBox(width: 8.6),
              _buildTriageItem(AppColors.triagePre_verde, incident.green),
              const SizedBox(width: 8.6),
              _buildTriageItem(AppColors.triagePre_negro, incident.black),
              const Spacer(),
              SvgPicture.asset(AppIcons.paramedicoHomeCantPersonas),
              const SizedBox(width: 4.5),
              Text(
                incident.totalVictims.toString(),
                style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                  color: const Color(0xFF999A9D),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
