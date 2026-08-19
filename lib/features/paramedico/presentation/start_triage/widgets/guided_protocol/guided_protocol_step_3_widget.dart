import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_3_data.dart';

class GuidedProtocolStep3Widget extends StatelessWidget {
  final GuidedProtocolStep3Data data;

  const GuidedProtocolStep3Widget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Niv. 3: Estado neurológico',
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
                  AppIcons.triageStartBrain,
                  width: 64,
                  height: 64,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿El paciente puede seguir órdenes?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.ESC_Bold_displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 40),
                _buildButton(
                  text: 'Sí, sigue órdenes',
                  color: Colors.white, // Blanco
                  textColor: const Color(0xFFCE1125), // Texto Rojo
                  onTap: data.onYesTap,
                ),
                const SizedBox(height: 16),
                _buildButton(
                  text: 'No responde',
                  color: const Color(0xFFCE1125), // Rojo
                  textColor: Colors.white, // Texto Blanco
                  onTap: data.onNoTap,
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
