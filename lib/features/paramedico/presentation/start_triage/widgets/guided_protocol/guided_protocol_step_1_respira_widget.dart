import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_1_respira_data.dart';

class GuidedProtocolStep1RespiraWidget extends StatelessWidget {
  final GuidedProtocolStep1RespiraData data;

  const GuidedProtocolStep1RespiraWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Niv. 1: Vía Aérea',
            style: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                SvgPicture.asset(
                  AppIcons.triageStartBreathing,
                  width: 64,
                  height: 64,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Si ',
                        style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: 'SÍ ',
                        style:
                            AppTextStyles.ESC_ExtraBold_displayLarge.copyWith(
                              color: const Color(0xFF22A63C), // Verde
                              fontSize: 20,
                            ),
                      ),
                      TextSpan(
                        text: 'respira:',
                        style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Frecuencia Respiratoria',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.ESC_ExtraBold_displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                _buildButton(
                  text: 'Mayor a 30 por minuto',
                  color: const Color(0xFFCE1125), // Rojo
                  textColor: Colors.white,
                  onTap: data.onRedButtonTap,
                ),
                const SizedBox(height: 16),
                _buildButton(
                  text: 'Menor a 30 por minuto',
                  color: const Color(0xFFF39C12), // Naranja adaptado a UI
                  textColor: Colors.white,
                  onTap: data.onOrangeButtonTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        height: 53,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.ESC_Black_displayLarge.copyWith(
            color: textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
