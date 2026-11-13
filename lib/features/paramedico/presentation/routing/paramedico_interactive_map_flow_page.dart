import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/map_layers_sheet.dart';

/// Mapa interactivo en pantalla completa con opción de retorno
class ParamedicoInteractiveMapFlowPage extends StatefulWidget {
  const ParamedicoInteractiveMapFlowPage({
    super.key,
    this.initialFocusIncidentId,
    this.initialFocusPatientId,
    this.returnTo,
  });

  final String? initialFocusIncidentId;
  final String? initialFocusPatientId;
  final String? returnTo;

  @override
  State<ParamedicoInteractiveMapFlowPage> createState() =>
      _ParamedicoInteractiveMapFlowPageState();
}

class _ParamedicoInteractiveMapFlowPageState
    extends State<ParamedicoInteractiveMapFlowPage> {
  late final ParamedicoMapController _controller;
  bool _loadHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = ParamedicoMapController(
      initialFocusIncidentId: widget.initialFocusIncidentId,
      initialFocusPatientId: widget.initialFocusPatientId,
    );
    _controller.addListener(_onController);
    _controller.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.onDependenciesChanged(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
    if (!_loadHandled && !_controller.loading) {
      _loadHandled = true;
      unawaited(_controller.onLoadComplete(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final selected = c.selectedIncident;
    final uid = c.currentUserId;

    return Theme(
      data: appTheme,
      child: Material(
        color: Colors.white,
        child: ParamedicoMapPage(
          searchController: c.searchController,
          onSearchSubmitted: (query) =>
              unawaited(c.searchAddress(context, query)),
          mapController: c.mapController,
          errorMessage: c.error,
          isLoading: c.loading,
          mappableIncidents: c.mappableIncidents,
          selectedIncidentId: c.selectedIncidentId,
          routePoints: c.routePoints,
          userPosition: c.userPosition,
          followUser: c.followUser,
          routing: c.routing,
          selectedCard: selected != null ? c.toCard(selected, uid) : null,
          onMapReady: c.markMapReady,
          onBack: () => c.navigateBack(context, returnTo: widget.returnTo),
          onMapBackgroundTap: c.onMapBackgroundTap,
          onMapPositionChanged: c.onMapPositionChanged,
          onPinTap: (inc) => unawaited(c.onPinTap(context, inc)),
          onClearSelection: c.clearSelection,
          onResumeNavigation: c.enableFollowNavigation,
          onLocateMe: () => unawaited(c.centerOnUser(context)),
          onOpenLayers: () => unawaited(showMapLayersSheet(context, c)),
          onOpenIncidentDetail: () {
            final id = c.selectedIncidentId;
            if (id != null) c.openIncidentDetail(context, id);
          },
          filter: c.filter,
          onFilterChanged: (f) => unawaited(c.setFilter(context, f)),
          countsByIncident: c.counts,
          hospitals: c.hospitals,
          showIncidents: c.showIncidents,
          showHospitals: c.showHospitals,
          showBackButton: true,
          coverageRings: c
              .visibleCoverageRings()
              .map((r) => (center: r.center, radiusMeters: r.radiusMeters))
              .toList(),
          patientPins: c.visiblePatientPins(),
          highlightedPatientId: c.highlightedPatientId,
          onPatientPinTap: (pin) => c.openPatientDetail(context, pin.id),
        ),
      ),
    );
  }
}
