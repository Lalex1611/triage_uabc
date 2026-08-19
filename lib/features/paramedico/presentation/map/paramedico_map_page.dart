import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/incident_card_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_operational_region.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/active_incidents_map_badge_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/incident_map_pin_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/map_incident_filter_chip_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/map_floating_controls_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/map_search_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/navigation_user_marker_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/patient_map_pin_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/resume_navigation_chip_widget.dart';

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
    this.coverageRings = const [],
    this.patientPins = const [],
    this.highlightedPatientId,
    this.onPatientPinTap,
    this.onMapReady,
  });

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
  final List<({LatLng center, double radiusMeters})> coverageRings;
  final List<MapPatientPin> patientPins;
  final String? highlightedPatientId;
  final void Function(MapPatientPin pin)? onPatientPinTap;
  final VoidCallback? onMapReady;

  @override
  Widget build(BuildContext context) {
    final selected = selectedCard;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MapSearchHeaderWidget(
            searchController: searchController,
            onBack: onBack,
            onSignOut: onSignOut,
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                errorMessage!,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  color: AppColors.primaryParamedico,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryParamedico,
                    ),
                  )
                : Stack(
                    children: [
                      FlutterMap(
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
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'sistema_triage',
                          ),
                          if (routePoints.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routePoints,
                                  color: AppColors.primaryParamedico.withValues(
                                    alpha: 0.82,
                                  ),
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
                                    color: AppColors.primaryParamedico
                                        .withValues(alpha: 0.10),
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
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
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
                                  width: 56,
                                  height: 56,
                                  alignment: Alignment.center,
                                  child: IncidentMapPin(
                                    selected: e.id == selectedIncidentId,
                                    onTap: () => onPinTap(e),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: ActiveIncidentsMapBadge(
                          count: mappableIncidents.length,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: MapIncidentFilterChip(
                          mineOnly: mineOnly,
                          onChanged: onMineOnlyChanged,
                        ),
                      ),
                      if (selected != null)
                        Positioned(
                          top: 58,
                          left: 5,
                          right: 5,
                          child: Material(
                            color: Colors.transparent,
                            elevation: 5,
                            shadowColor: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(13),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: AppColors.primaryParamedico.withValues(
                                    alpha: 0.55,
                                  ),
                                  width: 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IncidentCard(
                                    incident: selected,
                                    onTap: onOpenIncidentDetail,
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
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
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (selected != null && !followUser)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 72,
                          child: Center(
                            child: ResumeNavigationChip(
                              onResume: onResumeNavigation,
                            ),
                          ),
                        ),
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
          ),
        ],
      ),
    );
  }
}
