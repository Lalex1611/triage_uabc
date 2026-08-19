import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_metadata_data.dart';

// Tarjeta flotante de metadatos del incidente
class IncidentMetadataCard extends StatelessWidget {
  final IncidentMetadataData data;

  const IncidentMetadataCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const textGrey = Color(0xFF999A9D);
    const fontSize = 10.84;

    final labelStyle = AppTextStyles.ESC_Medium_bodyMedium.copyWith(
      color: textGrey,
      fontSize: fontSize,
    );

    final valueSemiBold = AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
      color: textGrey,
      fontSize: fontSize,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 68),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Creado por:', style: labelStyle),
              Text(data.creatorName, style: valueSemiBold),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hace:', style: labelStyle),
              Text(data.timeElapsedLabel, style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }
}
