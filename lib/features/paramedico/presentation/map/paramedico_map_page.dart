import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/incident_card_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_operational_region.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/map_floating_controls_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/navigation_user_marker_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/patient_map_pin_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/resume_navigation_chip_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Cascarón del mapa interactivo de incidentes (paramédico). Solo layout y callbacks
class ParamedicoMapPage extends StatelessWidget {
  const ParamedicoMapPage({
    super.key,
    required this.searchController,
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
    required this.onSignOut,
    required this.onMapBackgroundTap,
    required this.onMapPositionChanged,
    required this.onPinTap,
    required this.onClearSelection,
    required this.onResumeNavigation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocateMe,
    required this.onOpenIncidentDetail,
    required this.mineOnly,
    required this.onMineOnlyChanged,
    this.countsByIncident = const {},
    this.showBackButton = false,
    this.coverageRings = const [],
    this.patientPins = const [],
    this.highlightedPatientId,
    this.onPatientPinTap,
    this.onMapReady,
  });

  // searchController, onBack y onSignOut se conservan para no romper a quien
  // construye esta página; el buscador nuevo aún no tiene funcionalidad.
  final TextEditingController searchController;
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
  final VoidCallback onSignOut;
  final VoidCallback onMapBackgroundTap;
  final void Function(MapCamera camera, bool hasGesture) onMapPositionChanged;
  final void Function(ParamedicoIncidentSummary inc) onPinTap;
  final VoidCallback onClearSelection;
  final VoidCallback onResumeNavigation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocateMe;
  final VoidCallback onOpenIncidentDetail;
  final bool mineOnly;
  final ValueChanged<bool> onMineOnlyChanged;

  /// Conteo de pacientes por incidente (para el número rojo del marcador)
  final Map<String, IncidentPatientTriageCounts> countsByIncident;

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

  @override
  Widget build(BuildContext context) {
    final selected = selectedCard;

    return ColoredBox(
      color: TriageColors.surface,
      child: Stack(
        children: [
          Positioned.fill(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryParamedico,
                    ),
                  )
                : _buildMap(selected),
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
                          Material(
                            color: TriageColors.surface,
                            shape: const CircleBorder(
                              side: BorderSide(
                                color: TriageColors.borderSubtle,
                                width: TriageSizes.stroke,
                              ),
                            ),
                            child: IconButton(
                              onPressed: onBack,
                              tooltip: 'Volver',
                              constraints: const BoxConstraints.tightFor(
                                width: TriageSizes.touchTarget,
                                height: TriageSizes.touchTarget,
                              ),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: TriageColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: TriageSpacing.sm),
                        ],
                        // Sin controller: solo visual, no filtra incidentes
                        const Expanded(
                          child: TriageSearchBar(hint: 'Buscar dirección'),
                        ),
                      ],
                    ),
                    const SizedBox(height: TriageSpacing.sm),
                    Wrap(
                      spacing: TriageSpacing.sm,
                      runSpacing: TriageSpacing.sm,
                      children: [
                        TriageChip(
                          label: 'Mis incidentes',
                          selected: mineOnly,
                          onTap: () => onMineOnlyChanged(true),
                        ),
                        TriageChip(
                          label: 'Todos',
                          selected: !mineOnly,
                          onTap: () => onMineOnlyChanged(false),
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: TriageSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(TriageSpacing.sm),
                        decoration: BoxDecoration(
                          color: TriageColors.surface,
                          borderRadius: BorderRadius.circular(TriageRadii.full),
                        ),
                        child: Text(
                          errorMessage!,
                          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                            color: AppColors.primaryParamedico,
                            fontSize: 12,
                          ),
                        ),
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
              bottom: 72,
              child: Center(
                child: ResumeNavigationChip(onResume: onResumeNavigation),
              ),
            ),
          if (!isLoading)
            Positioned(
              right: 12,
              bottom: 12,
              child: MapFloatingControls(
                onZoomIn: onZoomIn,
                onZoomOut: onZoomOut,
                onLocateMe: onLocateMe,
                followActive: followUser && selected != null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(IncidentForCards? selected) {
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'sistema_triage',
        ),
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: AppColors.primaryParamedico.withValues(alpha: 0.82),
                strokeWidth: 4,
              ),
            ],
          ),
        if (coverageRings.isNotEmpty)
          CircleLayer(
            optimizeRadiusInMeters: true,
            circles: [
              for (final ring in coverageRings)
                CircleMarker(
                  point: ring.center,
                  radius: ring.radiusMeters,
                  useRadiusInMeter: true,
                  color: AppColors.primaryParamedico.withValues(alpha: 0.10),
                  borderColor: AppColors.primaryParamedico,
                  borderStrokeWidth: 1.5,
                ),
            ],
          ),
        if (userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userPosition!,
                width: followUser ? 40 : 28,
                height: followUser ? 40 : 28,
                child: followUser
                    ? const NavigationUserMarker()
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedico,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
              ),
            ],
          ),
        if (patientPins.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final p in patientPins)
                Marker(
                  point: LatLng(p.latitude, p.longitude),
                  width: 44,
                  height: 44,
                  alignment: Alignment.bottomCenter,
                  child: PatientMapPin(
                    triageColor: p.triageColor,
                    highlighted: p.id == highlightedPatientId,
                    onTap: onPatientPinTap != null
                        ? () => onPatientPinTap!(p)
                        : null,
                  ),
                ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final e in mappableIncidents)
              Marker(
                point: LatLng(e.latitude!, e.longitude!),
                width: _incidentMarkerWidth,
                height: TriageSizes.touchTarget,
                alignment: Alignment.center,
                child: TriageIncidentMarker(
                  redCount: countsByIncident[e.id]?.red ?? 0,
                  selected: e.id == selectedIncidentId,
                  onTap: () => onPinTap(e),
                ),
              ),
          ],
        ),
      ],
    );
  }

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
            color: AppColors.primaryParamedico.withValues(alpha: 0.55),
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
                color: AppColors.primaryParamedico,
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