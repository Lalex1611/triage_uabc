import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_map_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_map_widget.dart';

class DetailsMapWidget extends StatelessWidget {
  final DetailsMapData data;

  const DetailsMapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mapa Base Reutilizado
        PatientMapWidget(data: data.mapData),

        /* Bloque dinámico si el paciente está en TRASLADANDO */
        if (data.currentStatus == PatientStatus.trasladando &&
            data.assignedHospital != null) ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C74A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hospital de emergencia asignado: ${data.assignedHospital}',
                    style: AppTextStyles.ESC_Medium_bodyMedium.copyWith(
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (data.headingToText != null) ...[
            const SizedBox(height: 8),
            Text(
              data.headingToText!,
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                color: const Color(0xFF999A9D),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
