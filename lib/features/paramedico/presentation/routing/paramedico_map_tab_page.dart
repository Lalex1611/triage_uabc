import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/widgets/map_layers_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/routing/paramedico_shell_page.dart';

/// Vista principal del mapa paramédico
class ParamedicoMapTabPage extends StatefulWidget {
  const ParamedicoMapTabPage({super.key, this.initialFocusIncidentId});

  /// Incidente enfocado inicialmente al abrir desde detalles de incidente
  final String? initialFocusIncidentId;

  @override
  State<ParamedicoMapTabPage> createState() => _ParamedicoMapTabPageState();
}

class _ParamedicoMapTabPageState extends State<ParamedicoMapTabPage> {
  late final ParamedicoMapController _controller;
  bool _loadHandled = false;
  ValueNotifier<bool>? _navbarHidden;
  final _panelKey = GlobalKey();
  late final AppLifecycleListener _lifecycle;
  bool _tabVisible = false;

  @override
  void initState() {
    super.initState();
    _controller =
        ParamedicoMapController(
            initialFocusIncidentId: widget.initialFocusIncidentId,
          )
          ..panelHeight = (() => _panelKey.currentContext?.size?.height ?? 0)
          ..onSelectedIncidentClosed = () {
            if (mounted) showAppSnackBar(context, 'Este incidente se cerró.');
          };
    _controller.addListener(_onController);
    _controller.init();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _syncLive());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navbarHidden = ParamedicoNavbarVisibility.maybeOf(context);
    _controller.onDependenciesChanged(context);
    // Otra pestaña o una pantalla encima apagan los tickers del mapa
    _tabVisible = TickerMode.valuesOf(context).enabled;
    _syncLive();
  }

  /// GPS en vivo solo con el mapa a la vista y la app en primer plano
  void _syncLive() {
    final state = WidgetsBinding.instance.lifecycleState;
    final background = const {
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    }.contains(state);
    _controller.setLiveLocation(_tabVisible && !background);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _navbarHidden?.value = false;
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
    // Con un incidente elegido la barra se oculta (B03)
    _navbarHidden?.value = _controller.selectedIncidentId != null;
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

    // Con un incidente elegido, atrás lo suelta en vez de cerrar la app
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) c.back(context);
      },
      child: ParamedicoMapPage(
        searchController: c.searchController,
        onSearchSubmitted: (query) =>
            unawaited(c.searchAddress(context, query)),
        mapController: c.mapController,
        errorMessage: c.error,
        isLoading: c.loading,
        mappableIncidents: c.mappableIncidents,
        selectedIncidentId: c.selectedIncidentId,
        userPosition: c.userPosition,
        selectedCard: selected != null ? c.toCard(selected, uid) : null,
        onMapBackgroundTap: c.onMapBackgroundTap,
        onPinTap: c.onPinTap,
        onClearSelection: c.clearSelection,
        onDirections: () => unawaited(c.openDirections(context)),
        onReturnToPatient: c.returnToPatientId != null
            ? () => c.returnToPatient(context)
            : null,
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
        unreadNotifications: c.unreadNotifications,
        onOpenNotifications: () => unawaited(c.openNotifications(context)),
        coverageRingsFor: c.visibleCoverageRings,
        patientPinsFor: c.visiblePatientPins,
        highlightedPatientId: c.highlightedPatientId,
        onPatientPinTap: (pin) => c.openPatientDetail(context, pin.id),
        onMapReady: c.markMapReady,
        panelKey: _panelKey,
        isLocating: c.locating,
      ),
    );
  }
}
