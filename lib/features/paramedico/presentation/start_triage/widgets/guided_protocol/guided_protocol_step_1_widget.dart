import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_1_data.dart';

class GuidedProtocolStep1Widget extends StatelessWidget {
  final GuidedProtocolStep1Data data;

  const GuidedProtocolStep1Widget({super.key, required this.data});

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
                const SizedBox(height: 10),
                Text(
                  '¿El paciente respira?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.ESC_Bold_displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildButton(
                      text: 'No',
                      color: const Color(0xFFCE1125), // Rojo
                      onTap: data.onNoTap,
                    ),
                    const SizedBox(width: 16),
                    _buildButton(
                      text: 'Sí',
                      color: const Color(0xFF22A63C), // Verde
                      onTap: data.onYesTap,
                    ),
                  ],
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 33,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
