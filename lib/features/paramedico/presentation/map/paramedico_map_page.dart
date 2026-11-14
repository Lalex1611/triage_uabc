import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/util/time_ago.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_operational_region.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Cascarón del mapa en vivo de incidentes (paramédico): explorar (B01) e
// incidente elegido (B03). Solo layout y callbacks
class ParamedicoMapPage extends StatelessWidget {
  const ParamedicoMapPage({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.mapController,
    required this.errorMessage,
    required this.isLoading,
    required this.mappableIncidents,
    required this.selectedIncidentId,
    required this.userPosition,
    required this.selectedCard,
    required this.onMapBackgroundTap,
    required this.onMapPositionChanged,
    required this.onPinTap,
    required this.onDirections,
    required this.onLocateMe,
    required this.onOpenLayers,
    required this.onOpenIncidentDetail,
    required this.filter,
    required this.onFilterChanged,
    this.countsByIncident = const {},
    this.hospitals = const [],
    this.showIncidents = true,
    this.showHospitals = true,
    this.unreadNotifications = 0,
    this.onOpenNotifications,
    this.coverageRings = const [],
    this.patientPins = const [],
    this.highlightedPatientId,
    this.onPatientPinTap,
    this.onMapReady,
    this.selectedDistanceMeters,
    this.onReturnToPatient,
  });

  /// Buscador de direcciones: [onSearchSubmitted] mueve el mapa al resultado
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final MapController mapController;
  final String? errorMessage;
  final bool isLoading;
  final List<ParamedicoIncidentSummary> mappableIncidents;
  final String? selectedIncidentId;
  final LatLng? userPosition;

  /// Incidente elegido: su panel va abajo (B03)
  final IncidentForCards? selectedCard;
  final VoidCallback onMapBackgroundTap;
  final void Function(MapCamera camera, bool hasGesture) onMapPositionChanged;
  final void Function(ParamedicoIncidentSummary inc) onPinTap;

  /// "Cómo llegar": abre la ruta en Google Maps
  final VoidCallback onDirections;
  final VoidCallback onLocateMe;
  final VoidCallback onOpenLayers;
  final VoidCallback onOpenIncidentDetail;
  final MapIncidentFilter filter;
  final ValueChanged<MapIncidentFilter> onFilterChanged;

  /// Conteo de pacientes por incidente (el total va en el marcador)
  final Map<String, IncidentPatientTriageCounts> countsByIncident;
  final List<HospitalRow> hospitals;

  /// Capas del mapa: incidentes (con sus pacientes y radios) y hospitales
  final bool showIncidents;
  final bool showHospitals;

  /// Sin [onOpenNotifications] no se muestra la campana
  final int unreadNotifications;
  final VoidCallback? onOpenNotifications;
  final List<({LatLng center, double radiusMeters})> coverageRings;
  final List<MapPatientPin> patientPins;
  final String? highlightedPatientId;
  final void Function(MapPatientPin pin)? onPatientPinTap;
  final VoidCallback? onMapReady;

  /// En línea recta desde el usuario; sin GPS no se muestra
  final double? selectedDistanceMeters;

  /// Se llegó desde la ficha de un paciente: botón para volver a ella
  final VoidCallback? onReturnToPatient;

  // Marcador de incidente: ancho para "88" con aire; alto = zona táctil
  static const double _incidentMarkerWidth = 88;

  static const _filterLabels = {
    MapIncidentFilter.mine: 'Mis incidentes',
    MapIncidentFilter.all: 'Todos',
    MapIncidentFilter.nearby: 'Cerca de mí',
  };

  /// "850 m" o "1.4 km"
  static String _formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final selected = selectedCard;
    final onOpenNotifications = this.onOpenNotifications;

    return ColoredBox(
      color: TriageColors.surface,
      child: Stack(
        children: [
          Positioned.fill(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: TriageColors.paramedicAccent,
                    ),
                  )
                : _buildMap(),
          ),
          // Buscador y filtros flotan sobre el mapa
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TriageSpacing.lg,
                  TriageSpacing.sm,
                  TriageSpacing.lg,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TriageSearchBar(
                            hint: 'Buscar dirección',
                            controller: searchController,
                            onSubmitted: onSearchSubmitted,
                          ),
                        ),
                        if (onOpenNotifications != null) ...[
                          const SizedBox(width: TriageSpacing.sm),
                          TriageIconButton(
                            icon: TriageIcons.bell,
                            tooltip: unreadNotifications > 0
                                ? 'Notificaciones, $unreadNotifications sin leer'
                                : 'Notificaciones',
                            onPressed: onOpenNotifications,
                            variant: TriageIconButtonVariant.surface,
                            diameter: TriageSizes.touchTarget,
                            showDot: unreadNotifications > 0,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: TriageSpacing.sm),
                    Wrap(
                      spacing: TriageSpacing.sm,
                      runSpacing: TriageSpacing.sm,
                      children: [
                        for (final entry in _filterLabels.entries)
                          TriageChip(
                            label: entry.value,
                            selected: filter == entry.key,
                            onTap: () => onFilterChanged(entry.key),
                          ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: TriageSpacing.sm),
                      TriageAlert(
                        tone: TriageTone.danger,
                        title: 'No se pudieron cargar los incidentes',
                        message: errorMessage,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!isLoading)
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: TriageSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TriageIconButton(
                        icon: TriageIcons.target,
                        tooltip: 'Centrar en mi ubicación',
                        onPressed: onLocateMe,
                        variant: TriageIconButtonVariant.surface,
                        diameter: TriageSizes.touchTarget,
                      ),
                      const SizedBox(height: TriageSpacing.sm),
                      TriageIconButton(
                        icon: TriageIcons.layers,
                        tooltip: 'Capas del mapa',
                        onPressed: onOpenLayers,
                        variant: TriageIconButtonVariant.surface,
                        diameter: TriageSizes.touchTarget,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (selected != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildIncidentPanel(selected),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final user = userPosition;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: MapOperationalRegion.overviewCenter,
        initialZoom: MapOperationalRegion.overviewZoom,
        onMapReady: onMapReady,
        onTap: (_, _) => onMapBackgroundTap(),
        onPositionChanged: onMapPositionChanged,
      ),
      children: [
        const TriageMapTiles(),
        if (showIncidents && coverageRings.isNotEmpty)
          CircleLayer(
            optimizeRadiusInMeters: true,
            circles: [
              for (final ring in coverageRings)
                CircleMarker(
                  point: ring.center,
                  radius: ring.radiusMeters,
                  useRadiusInMeter: true,
                  color: TriageColors.paramedicAccent.withValues(
                    alpha: TriageOpacity.hover,
                  ),
                  borderColor: TriageColors.paramedicAccent,
                  borderStrokeWidth: TriageSizes.strokeStrong,
                ),
            ],
          ),
        if (showHospitals && hospitals.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final h in hospitals)
                Marker(
                  point: LatLng(h.latitude!, h.longitude!),
                  width: TriageSizes.touchTarget,
                  height: TriageSizes.touchTarget,
                  child: TriageHospitalMarker(semanticLabel: h.name),
                ),
            ],
          ),
        if (user != null)
          MarkerLayer(
            markers: [
              Marker(
                point: user,
                width: TriageUserMarker.haloDiameter,
                height: TriageUserMarker.haloDiameter,
                child: const TriageUserMarker(showHalo: true),
              ),
            ],
          ),
        if (showIncidents && patientPins.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final p in patientPins)
                Marker(
                  point: LatLng(p.latitude, p.longitude),
                  width: TriageSizes.touchTarget,
                  height: TriageSizes.touchTarget,
                  child: TriagePatientMarker(
                    TriageLevel.fromDb(p.triageColor) ?? TriageLevel.yellow,
                    highlighted: p.id == highlightedPatientId,
                    onTap: onPatientPinTap != null
                        ? () => onPatientPinTap!(p)
                        : null,
                  ),
                ),
            ],
          ),
        if (showIncidents)
          MarkerLayer(
            markers: [
              for (final e in mappableIncidents)
                Marker(
                  point: LatLng(e.latitude!, e.longitude!),
                  width: _incidentMarkerWidth,
                  height: TriageSizes.touchTarget,
                  alignment: Alignment.center,
                  child: TriageIncidentMarker(
                    patientCount: countsByIncident[e.id]?.total ?? 0,
                    selected: e.id == selectedIncidentId,
                    onTap: () => onPinTap(e),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Panel del incidente elegido (B03)
  Widget _buildIncidentPanel(IncidentForCards incident) {
    final distance = selectedDistanceMeters;
    final onReturnToPatient = this.onReturnToPatient;

    return TriageSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TriageSpacing.xl,
          TriageSpacing.sm,
          TriageSpacing.xl,
          TriageSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TriageIncidentCard(
              folio: incident.id,
              timeAgo: timeAgo(incident.dateTime),
              title: incident.name_card,
              location: distance == null
                  ? incident.coordinatesLabel
                  : '${incident.coordinatesLabel} · a '
                        '${_formatDistance(distance)}',
              counts: {
                TriageLevel.red: incident.red,
                TriageLevel.yellow: incident.yellow,
                TriageLevel.green: incident.green,
                TriageLevel.black: incident.black,
              },
              patientCount: incident.totalVictims,
              selected: true,
              onTap: onOpenIncidentDetail,
            ),
            const SizedBox(height: TriageSpacing.md),
            if (onReturnToPatient != null) ...[
              TriageButton(
                label: 'Volver al paciente',
                variant: TriageButtonVariant.subtle,
                size: TriageButtonSize.medium,
                onPressed: onReturnToPatient,
              ),
              const SizedBox(height: TriageSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: TriageButton(
                    label: 'Cómo llegar',
                    variant: TriageButtonVariant.secondary,
                    onPressed: onDirections,
                  ),
                ),
                const SizedBox(width: TriageSpacing.md),
                Expanded(
                  child: TriageButton(
                    label: 'Abrir incidente',
                    onPressed: onOpenIncidentDetail,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
