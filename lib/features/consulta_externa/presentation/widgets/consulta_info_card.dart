import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

class ConsultaInfoCard extends StatelessWidget {
  /// Variante visual de A04; las pantallas de estado conservan su presentación.
  final bool outlined;

  const ConsultaInfoCard({super.key, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(outlined ? 18 : 20),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(outlined ? 20 : 16),
        border: outlined
            ? Border.all(color: const Color(0xFFE6EBF1), width: 1.25)
            : null,
        boxShadow: outlined
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
            style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
              fontSize: outlined ? 15 : 20,
              height: outlined ? 1.33 : null,
              color: outlined ? const Color(0xFF121924) : null,
            ),
          ),
          SizedBox(height: outlined ? 12 : 16),
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
          width: outlined ? 18 : 20,
          height: outlined ? 18 : 20,
          colorFilter: ColorFilter.mode(
            outlined ? const Color(0xFF8695A8) : Colors.black,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(width: outlined ? 10 : 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              fontSize: outlined ? 13 : 12,
              height: outlined ? 1.46 : null,
              color: outlined
                  ? const Color(0xFF4A5667)
                  : const Color(0xFF7B7B7B),
            ),
          ),
        ),
      ],
    );
  }
}
