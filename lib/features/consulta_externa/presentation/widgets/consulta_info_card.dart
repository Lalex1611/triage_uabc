import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

class ConsultaInfoCard extends StatelessWidget {
  const ConsultaInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo funciona?',
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            AppIcons.consultaSecurity,
            'No requiere crear cuenta ni proporcionar datos personales.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            AppIcons.consultaClock,
            'Los códigos tienen vigencia temporal y son generados por el personal de Cruz Roja o el hospital.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            AppIcons.consultaFavourite,
            'Solo verás la información correspondiente a tu código. No se muestran datos clínicos sensibles.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String iconAsset, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: 12,
              color: const Color(0xFF7B7B7B),
            ),
          ),
        ),
      ],
    );
  }
}
