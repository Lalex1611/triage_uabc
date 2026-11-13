import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/incident_card_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_operational_region.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/navigation_user_marker_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/resume_navigation_chip_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Cascarón del mapa en vivo de incidentes (paramédico, B01). Solo layout y callbacks
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
    required this.routePoints,
    required this.userPosition,
    required this.followUser,
    required this.routing,
    required this.selectedCard,
    required this.onBack,
    required this.onMapBackgroundTap,
    required this.onMapPositionChanged,
    required this.onPinTap,
    required this.onClearSelection,
    required this.onResumeNavigation,
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
    this.showBackButton = false,
    this.coverageRings = const [],
    this.patientPins = const [],
    this.highlightedPatientId,
    this.onPatientPinTap,
    this.onMapReady,
  });

  /// Buscador de direcciones: [onSearchSubmitted] mueve el mapa al resultado
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final MapController mapController;
  final String? errorMessage;
  final bool isLoading;
  final List<ParamedicoIncidentSummary> mappableIncidents;
  final String? selectedIncidentId;
  final List<LatLng> routePoints;
  final LatLng? userPosition;
  final bool followUser;
  final bool routing;
  final IncidentForCards? selectedCard;
  final VoidCallback onBack;
  final VoidCallback onMapBackgroundTap;
  final void Function(MapCamera camera, bool hasGesture) onMapPositionChanged;
  final void Function(ParamedicoIncidentSummary inc) onPinTap;
  final VoidCallback onClearSelection;
  final VoidCallback onResumeNavigation;
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

  /// Botón de volver junto al buscador. Solo para el mapa a pantalla completa
  /// (sin barra inferior); en la pestaña Mapa va en false.
  final bool showBackButton;
  final List<({LatLng center, double radiusMeters})> coverageRings;
  final List<MapPatientPin> patientPins;
  final String? highlightedPatientId;
  final void Function(MapPatientPin pin)? onPatientPinTap;
  final VoidCallback? onMapReady;

  // Marcador de incidente: ancho para "88" con aire; alto = zona táctil
  static const double _incidentMarkerWidth = 88;

  static const _filterLabels = {
    MapIncidentFilter.mine: 'Mis incidentes',
    MapIncidentFilter.all: 'Todos',
    MapIncidentFilter.nearby: 'Cerca de mí',
  };

  @override
  Widget build(BuildContext context) {
    final selected = selectedCard;
    final onOpenNotifications = this.onOpenNotifications;
    // Alto de la barra de navegación flotante (o del sistema) bajo el mapa
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
          // Buscador, filtros y tarjeta del incidente seleccionado flotan sobre el mapa
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
                        if (showBackButton) ...[
                          TriageIconButton(
                            icon: TriageIcons.arrowLeft,
                            tooltip: 'Volver',
                            onPressed: onBack,
                            variant: TriageIconButtonVariant.surface,
                          ),
                          const SizedBox(width: TriageSpacing.sm),
                        ],
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
                    if (selected != null) ...[
                      const SizedBox(height: TriageSpacing.sm),
                      _buildSelectedCard(selected),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!isLoading && selected != null && !followUser)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 72,
              child: Center(
                child: ResumeNavigationChip(onResume: onResumeNavigation),
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
                        // Siguiendo al usuario en la ruta: el botón lo indica
                        color: followUser && selected != null
                            ? TriageColors.paramedicAccent
                            : TriageColors.textPrimary,
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
        interactionOptions: InteractionOptions(
          flags: followUser
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.all,
        ),
      ),
      children: [
        const TriageMapTiles(),
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: TriageColors.paramedicAccent,
                strokeWidth: 4,
              ),
            ],
          ),
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
              followUser
                  ? Marker(
                      point: user,
                      width: 40,
                      height: 40,
                      child: const NavigationUserMarker(),
                    )
                  : Marker(
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

  // shortcut: tarjeta antigua del incidente seleccionado; se migra con B03
  Widget _buildSelectedCard(IncidentForCards selected) {
    return Material(
      color: Colors.transparent,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: TriageColors.paramedicAccent.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IncidentCard(incident: selected, onTap: onOpenIncidentDetail),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close, size: 22),
                color: TriageColors.paramedicAccent,
                tooltip: 'Salir de navegación',
                onPressed: onClearSelection,
              ),
            ),
            if (routing)
              const Positioned(
                right: 40,
                top: 8,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
