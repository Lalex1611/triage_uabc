import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

/// Pie de login con logos institucionales (SVG desde Wikimedia Commons)
class AuthPartnerLogosFooter extends StatelessWidget {
  const AuthPartnerLogosFooter({super.key});

  static const _cruzRoja = 'assets/icons/partners/cruz_roja_emblem.svg';
  static const _uabc = 'assets/icons/partners/uabc_logo.svg';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(
            'En colaboración con',
            textAlign: TextAlign.center,
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              fontSize: 11,
              color: const Color(0xFF999A9D),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: 'Cruz Roja',
                  child: SvgPicture.asset(
                    _cruzRoja,
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFFE8E8E8),
              ),
              Expanded(
                child: Semantics(
                  label: 'Universidad Autónoma de Baja California',
                  child: SvgPicture.asset(
                    _uabc,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Emblemas con fines informativos. Cruz Roja: Wikimedia Commons '
            '(dominio público). UABC: «Logo de la UABC (1966-2017)», '
            'Wikimedia Commons, CC BY-SA 4.0.',
            textAlign: TextAlign.center,
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              fontSize: 8,
              height: 1.25,
              color: const Color(0xFFBDBEC1),
            ),
          ),
        ],
      ),
    );
  }
}
