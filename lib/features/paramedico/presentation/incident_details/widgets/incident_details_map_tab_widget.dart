import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Pestaña Mapa del incidente (B08): zona de cobertura y pacientes en un mapa que
/// se mueve y se acerca dentro de la sección
class IncidentDetailsMapTab extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final List<MapPatientPin> patients;
  final ValueChanged<String>? onPatientTap;

  const IncidentDetailsMapTab({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.patients,
    this.onPatientTap,
  });

  @override
  State<IncidentDetailsMapTab> createState() => _IncidentDetailsMapTabState();
}

class _IncidentDetailsMapTabState extends State<IncidentDetailsMapTab> {
  static const double _minZoom = 3;
  static const double _maxZoom = 19;
  static const double _maxFitZoom = 18;
  static const double _coverageOpacity = 0.12;

  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  CameraFit _fit(LatLng center, double radius) => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(
      MapIncidentCoverageService.boundsPointsForIncident(
        incidentCenter: center,
        patients: widget.patients,
        radiusMeters: radius,
      ),
    ),
    padding: const EdgeInsets.all(TriageSizes.touchTarget),
    maxZoom: _maxFitZoom,
  );

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _mapController.move(
      camera.center,
      (camera.zoom + delta).clamp(_minZoom, _maxZoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latitude = widget.latitude;
    final longitude = widget.longitude;
    if (latitude == null || longitude == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TriageSpacing.xxl),
          child: Text(
            'Este incidente no tiene coordenadas registradas.\n'
            'Quien lo creó puede fijarlas desde Más opciones.',
            textAlign: TextAlign.center,
            style: TriageTextStyles.bodyMedium.copyWith(
              color: TriageColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final center = LatLng(latitude, longitude);
    final radius = MapIncidentCoverageService.radiusMeters(
      center,
      widget.patients,
    );
    final onPatientTap = widget.onPatientTap;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: _fit(center, radius),
            backgroundColor: TriageColors.sunken,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            const TriageMapTiles(),
            CircleLayer(
              optimizeRadiusInMeters: true,
              circles: [
                CircleMarker(
                  point: center,
                  radius: radius,
                  useRadiusInMeter: true,
                  color: context.triageRole.accent.withValues(
                    alpha: _coverageOpacity,
                  ),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (widget.patients.isEmpty)
                  Marker(
                    point: center,
                    width: TriageSizes.touchTarget,
                    height: TriageSizes.touchTarget,
                    alignment: Alignment.topCenter,
                    child: TriageIcon(
                      TriageIcons.location,
                      size: TriageSizes.touchTarget,
                      color: context.triageRole.accent,
                    ),
                  ),
                for (final patient in widget.patients)
                  Marker(
                    point: LatLng(patient.latitude, patient.longitude),
                    width: TriageSizes.touchTarget,
                    height: TriageSizes.touchTarget,
                    child: TriagePatientMarker(
                      TriageLevel.fromDb(patient.triageColor) ??
                          TriageLevel.green,
                      onTap: onPatientTap == null
                          ? null
                          : () => onPatientTap(patient.id),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding,
            vertical: TriageSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: TriageSpacing.sm,
            children: [
              // Solo informa: los gestos pasan al mapa
              Flexible(child: IgnorePointer(child: _Legend(widget.patients))),
              // Vertical: si el mapa queda bajo, los botones pasan a otra columna
              Wrap(
                direction: Axis.vertical,
                children: [
                  TriageIconButton(
                    icon: TriageIcons.target,
                    tooltip: 'Centrar en el incidente',
                    variant: TriageIconButtonVariant.surface,
                    onPressed: () =>
                        _mapController.fitCamera(_fit(center, radius)),
                  ),
                  TriageIconButton(
                    icon: TriageIcons.plus,
                    tooltip: 'Acercar',
                    variant: TriageIconButtonVariant.surface,
                    onPressed: () => _zoomBy(1),
                  ),
                  TriageIconButton(
                    icon: TriageIcons.minus,
                    tooltip: 'Alejar',
                    variant: TriageIconButtonVariant.surface,
                    onPressed: () => _zoomBy(-1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cuántos pacientes de cada nivel START hay sobre el mapa
class _Legend extends StatelessWidget {
  const _Legend(this.patients);

  final List<MapPatientPin> patients;

  static const double _dotSize = 10;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final level in TriageLevel.startLevels)
        level: patients
            .where((p) => TriageLevel.fromDb(p.triageColor) == level)
            .length,
    };

    return Semantics(
      label: [
        for (final MapEntry(key: level, value: count) in counts.entries)
          '${level.label}: $count',
      ].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TriageColors.surface,
          borderRadius: BorderRadius.circular(TriageRadii.lg),
          boxShadow: TriageShadows.floating,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TriageSpacing.md,
            vertical: TriageSpacing.sm,
          ),
          child: Wrap(
            spacing: TriageSpacing.md,
            runSpacing: TriageSpacing.xs,
            children: [
              for (final MapEntry(key: level, value: count) in counts.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: TriageSpacing.xs,
                  children: [
                    SizedBox.square(
                      dimension: _dotSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: level.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: TriageTextStyles.labelMedium.copyWith(
                        color: TriageColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
