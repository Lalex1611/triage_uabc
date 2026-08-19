import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';

/// Marcador de paciente para el mapa interactivo (color según nivel de triage)
class PatientMapPin extends StatelessWidget {
  final String triageColor;
  final bool highlighted;
  final VoidCallback? onTap;

  const PatientMapPin({
    super.key,
    required this.triageColor,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = highlighted ? 40.0 : 32.0;
    final iconPath = MapIncidentCoverageService.triageLocationIcon(triageColor);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (highlighted)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCE1125), width: 2.5),
                ),
              ),
            SvgPicture.asset(
              iconPath,
              width: size * 0.88,
              height: size * 0.88,
            ),
          ],
        ),
      ),
    );
  }
}
