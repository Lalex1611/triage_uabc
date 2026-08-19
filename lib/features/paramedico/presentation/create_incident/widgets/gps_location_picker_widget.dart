import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/captured_gps_row_widget.dart';

// Coordenadas GPS del incidente en creación (pin, Mostrar, Editar)
class GpsLocationPicker extends StatelessWidget {
  final double latitude;
  final double longitude;
  final VoidCallback onShowMap;
  final VoidCallback onEditManual;

  const GpsLocationPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onShowMap,
    required this.onEditManual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: CapturedGpsRowWidget(
        coordinates:
            '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
        onShowTap: onShowMap,
        onEditTap: onEditManual,
        iconAssetPath: AppIcons.paramedicoIncidenteLocation,
      ),
    );
  }
}
