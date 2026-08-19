import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_header_data.dart';

class StartTriageHeaderWidget extends StatelessWidget {
  final StartTriageHeaderData data;

  const StartTriageHeaderWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(
        10.0,
      ), // Padding de 10 respecto a los bordes
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Gap en Auto
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                data.headline,
                style: AppTextStyles.ESC_Light_displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 30, // Tamaño 30 según diseño
                ),
              ),
              GestureDetector(
                onTap: data.onCloseTap,
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 45, // Tamaño de 45 fijo según Figma
                ),
              ),
            ],
          ),
          /* El diseño muestra muy poca separación entre START TRIAGE y No. de Paciente */
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: 'No. de Paciente: ',
              style: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 20, // Thin de 20pts
              ),
              children: [
                TextSpan(
                  text: data.patientNumber.toString(),
                  style: AppTextStyles.ESC_Regular_bodyLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20, // Regular de 20pts
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
