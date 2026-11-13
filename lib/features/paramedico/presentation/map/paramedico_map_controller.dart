import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_geocoding_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_navigation_helpers.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_operational_region.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_route_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_incidents_store.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_notifications_action.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Filtros del mapa en vivo (B01)
enum MapIncidentFilter { mine, all, nearby }

// Orquestador del mapa interactivo de incidentes: carga, rutas, GPS y selección de pin
class ParamedicoMapController extends ChangeNotifier {
  ParamedicoMapController({
    this.initialFocusIncidentId,
    this.initialFocusPatientId,
    ParamedicoIncidentsRepository? repository,
    ParamedicNotificationsRepository? notificationsRepository,
    MapRouteService? routeService,
    MapGeocodingService? geocodingService,
    MapController? mapController,
    TextEditingController? searchController,
    ParamedicoIncidentsStore? store,
  }) : _store = store ?? ParamedicoIncidentsStore.instance,
       _repo = repository ?? ParamedicoIncidentsRepository(),
       _notificationsRepo =
           notificationsRepository ?? ParamedicNotificationsRepository(),
       _routeService = routeService ?? MapRouteService(),
       _geocoding = geocodingService ?? MapGeocodingService(),
       mapController = mapController ?? MapController(),
       searchController = searchController ?? TextEditingController();

  /// Radio del filtro "Cerca de mí"
  static const double nearbyRadiusMeters = 5000;

  static bool isNearby(LatLng user, LatLng point) =>
      const Distance().as(LengthUnit.Meter, user, point) <= nearbyRadiusMeters;

  final String? initialFocusIncidentId;
  final String? initialFocusPatientId;
  final ParamedicoIncidentsStore _store;
  final ParamedicoIncidentsRepository _repo;
  final ParamedicNotificationsRepository _notificationsRepo;
  final MapRouteService _routeService;
  final MapGeocodingService _geocoding;
  final MapController mapController;

  /// Buscador de direcciones (no filtra incidentes)
  final TextEditingController searchController;

  // Datos compartidos con la hoja de incidentes, al día por tiempo real
  List<ParamedicoIncidentSummary> get incidents => _store.incidents;
  Map<String, IncidentPatientTriageCounts> get counts => _store.counts;
  Map<String, List<MapPatientPin>> get patientsByIncident =>
      _store.patientsByIncident;
  Map<String, double> get radiusMetersByIncident =>
      _store.radiusMetersByIncident;
  bool get loading => !_store.loaded && _store.error == null;
  String? get error => _store.error;

  /// Hospitales activos con coordenadas
  List<HospitalRow> hospitals = [];
  int unreadNotifications = 0;

  // Capas del mapa (panel "Capas del mapa")
  bool showIncidents = true;
  bool showHospitals = true;
  String? selectedIncidentId;
  List<LatLng> routePoints = [];
  LatLng? userPosition;
  LatLng? previousUserPosition;
  double? userHeading;
  List<LatLng> fullRoutePoints = [];
  bool followUser = false;
  MapIncidentFilter filter = MapIncidentFilter.all;
  bool routing = false;
  String? pendingFocusId;
  String? pendingFocusPatientId;
  String? _lastRouteUri;
  String? highlightedPatientId;
  String? forceShowPatientsIncidentId;
  int? _visibilityEpoch;
  bool _mapReady = false;
  VoidCallback? _pendingWhenMapReady;
  int _focusGeneration = 0;
  // Solo cuenta la última elección de filtro o búsqueda: una respuesta lenta
  // (GPS, geocodificador) no pisa lo que el usuario eligió después
  int _filterGeneration = 0;
  int _searchGeneration = 0;
  bool _disposed = false;

  StreamSubscription<Position>? _positionSub;

  // Las cargas en curso pueden terminar con la pantalla ya cerrada
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(_onStoreChanged);
    _positionSub?.cancel();
    searchController.dispose();
    mapController.dispose();
    super.dispose();
  }

  /// "Cerca de mí" necesita la ubicación: si no se consigue, avisa y no cambia
  Future<void> setFilter(BuildContext context, MapIncidentFilter value) async {
    final generation = ++_filterGeneration;
    if (filter == value) return;
    if (value == MapIncidentFilter.nearby && userPosition == null) {
      final pos = await IncidentLocationService.getCurrentPosition();
      if (!context.mounted || generation != _filterGeneration) return;
      if (pos == null) {
        showAppSnackBar(
          context,
          IncidentLocationService.errorMessageForNullResult() ??
              'Sin ubicación GPS.',
          isError: true,
        );
        return;
      }
      userPosition = LatLng(pos.lat, pos.lng);
    }
    filter = value;
    if (selectedIncidentId != null &&
        !visibleIncidents.any((e) => e.id == selectedIncidentId)) {
      _stopPositionStream();
      selectedIncidentId = null;
      forceShowPatientsIncidentId = null;
      highlightedPatientId = null;
      routePoints = [];
      fullRoutePoints = [];
      followUser = false;
      userHeading = null;
      previousUserPosition = null;
    }
    notifyListeners();
    if (value == MapIncidentFilter.nearby) {
      _fitNearbyArea();
    } else {
      goToRegionOverview();
    }
  }

  /// Encuadra el círculo de "Cerca de mí" alrededor del usuario
  void _fitNearbyArea() {
    final user = userPosition;
    if (user == null) return;
    const distance = Distance();
    _safeMapOp(() {
      mapController.rotate(0);
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            for (final bearing in const [0.0, 90.0, 180.0, 270.0])
              distance.offset(user, nearbyRadiusMeters, bearing),
          ]),
          padding: const EdgeInsets.all(56),
        ),
      );
    });
  }

  void setShowIncidents(bool value) {
    showIncidents = value;
    notifyListeners();
  }

  void setShowHospitals(bool value) {
    showHospitals = value;
    notifyListeners();
  }

  /// Mueve el mapa a la dirección buscada, priorizando la zona del usuario
  Future<void> searchAddress(BuildContext context, String query) async {
    final text = query.trim();
    if (text.isEmpty) return;
    final generation = ++_searchGeneration;
    final found = await _geocoding.search(
      text,
      near: userPosition ?? MapOperationalRegion.overviewCenter,
    );
    if (!context.mounted || generation != _searchGeneration) return;
    if (found == null) {
      showAppSnackBar(
        context,
        'No encontramos esa dirección. Prueba con calle y colonia.',
        isError: true,
      );
      return;
    }
    // Seguir al usuario devolvería la cámara a su posición
    if (followUser) {
      followUser = false;
      notifyListeners();
    }
    _safeMapOp(() => mapController.move(found, 16));
  }

  Future<void> refreshUnreadNotifications() async {
    if (!SupabaseEnv.isConfigured) return;
    unreadNotifications = await ParamedicoNotificationsAction.unreadCount(
      _notificationsRepo,
    );
    notifyListeners();
  }

  Future<void> openNotifications(BuildContext context) {
    return ParamedicoNotificationsAction.open(
      context,
      repository: _notificationsRepo,
      onUnreadChanged: (count) {
        unreadNotifications = count;
        notifyListeners();
      },
    );
  }

  Future<void> _loadHospitals() async {
    if (!SupabaseEnv.isConfigured) return;
    try {
      final list = await _repo.listActiveHospitals();
      hospitals = [
        for (final h in list)
          if (h.latitude != null && h.longitude != null) h,
      ];
      notifyListeners();
    } catch (_) {
      // Capa secundaria: sin hospitales el mapa de incidentes sigue sirviendo
    }
  }

  /// Llamar desde [MapOptions.onMapReady] cuando [FlutterMap] ya está montado
  void markMapReady() {
    if (_mapReady) return;
    _mapReady = true;
    final pending = _pendingWhenMapReady;
    _pendingWhenMapReady = null;
    pending?.call();
  }

  void _runWhenMapReady(void Function() action) {
    if (_mapReady) {
      action();
    } else {
      _pendingWhenMapReady = action;
    }
  }

  void _safeMapOp(void Function() op) {
    _runWhenMapReady(() {
      try {
        op();
      } catch (_) {
        // El mapa aún no está listo; reintentar tras onMapReady
        _mapReady = false;
        _runWhenMapReady(op);
      }
    });
  }

  void init() {
    pendingFocusId = initialFocusIncidentId;
    pendingFocusPatientId = initialFocusPatientId;
    // Escucharlo pone en marcha su carga y el tiempo real si aún no lo estaban
    _store.addListener(_onStoreChanged);
    unawaited(_initUserPosition());
    unawaited(_loadHospitals());
    unawaited(refreshUnreadNotifications());
  }

  /// Si el incidente elegido se cerró o borró (aquí o en otro dispositivo),
  /// se suelta en vez de seguir mostrándolo
  void _onStoreChanged() {
    final selected = selectedIncidentId;
    if (selected != null && _store.byId(selected) == null) {
      clearSelection();
    } else {
      notifyListeners();
    }
  }

  /// Enfoca lo que pida la ruta (`?focus=` y opcionalmente `&focusPatient=`)
  /// cada vez que cambia, también si se vuelve a pedir el mismo incidente
  /// para resaltar otro paciente
  void syncFocusFromRoute(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final key = uri.toString();
    if (key == _lastRouteUri) return;
    _lastRouteUri = key;
    final focus = uri.queryParameters['focus'];
    if (focus == null || focus.isEmpty) return;
    final patient = uri.queryParameters['focusPatient'];
    pendingFocusId = focus;
    pendingFocusPatientId = patient != null && patient.isNotEmpty
        ? patient
        : null;
  }

  void onDependenciesChanged(BuildContext context) {
    syncFocusFromRoute(context);
    if (!loading && pendingFocusId != null) {
      unawaited(applyPendingFocus(context));
    }
  }

  Future<void> _initUserPosition() async {
    final pos = await IncidentLocationService.getCurrentPosition();
    if (pos == null) return;
    userPosition = LatLng(pos.lat, pos.lng);
    notifyListeners();
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: followUser ? 8 : 20,
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Position pos) {
    final current = LatLng(pos.latitude, pos.longitude);
    final heading = MapNavigationHelpers.resolveHeading(
      position: pos,
      previous: previousUserPosition,
      current: current,
      lastHeading: userHeading,
    );

    previousUserPosition = userPosition;
    userPosition = current;
    userHeading = heading;
    if (fullRoutePoints.length >= 2) {
      routePoints = MapNavigationHelpers.trimRouteAhead(
        route: fullRoutePoints,
        user: current,
      );
    }
    notifyListeners();

    if (followUser) {
      updateNavigationCamera(animated: true);
    }

    final sel = selectedIncident;
    if (sel != null && sel.latitude != null && sel.longitude != null) {
      unawaited(loadRouteTo(sel, moveCamera: false));
    }
  }

  void _stopPositionStream() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> onLoadComplete(BuildContext context) async {
    _runWhenMapReady(() {
      unawaited(_runInitialCamera(context));
    });
  }

  Future<void> _runInitialCamera(BuildContext context) async {
    if (pendingFocusId != null) {
      await applyPendingFocus(context);
    } else {
      goToRegionOverview();
    }
  }

  List<ParamedicoIncidentSummary> get visibleIncidents {
    final uid = currentUserId;
    final user = userPosition;
    return switch (filter) {
      MapIncidentFilter.mine when uid.isNotEmpty =>
        incidents.where((e) => e.createdBy == uid).toList(),
      MapIncidentFilter.nearby when user != null =>
        incidents
            .where(
              (e) =>
                  e.latitude != null &&
                  e.longitude != null &&
                  isNearby(user, LatLng(e.latitude!, e.longitude!)),
            )
            .toList(),
      _ => incidents,
    };
  }

  List<ParamedicoIncidentSummary> get mappableIncidents => visibleIncidents
      .where((e) => e.latitude != null && e.longitude != null)
      .toList();

  ParamedicoIncidentSummary? get selectedIncident {
    if (selectedIncidentId == null) return null;
    for (final e in incidents) {
      if (e.id == selectedIncidentId) return e;
    }
    return null;
  }

  void goToRegionOverview() {
    _safeMapOp(() {
      mapController.rotate(0);
      final inRegion = mappableIncidents
          .where(
            (e) => MapOperationalRegion.contains(e.latitude!, e.longitude!),
          )
          .toList();

      if (inRegion.length >= 2) {
        final points = _overviewBoundsPoints(inRegion);
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(56),
            maxZoom: 14,
          ),
        );
        return;
      }

      if (inRegion.length == 1) {
        final inc = inRegion.first;
        final center = LatLng(inc.latitude!, inc.longitude!);
        final patients = patientsByIncident[inc.id] ?? const [];
        final radius =
            radiusMetersByIncident[inc.id] ??
            MapIncidentCoverageService.radiusMeters(center, patients);
        final points = MapIncidentCoverageService.boundsPointsForIncident(
          incidentCenter: center,
          patients: patients,
          radiusMeters: radius,
        );
        if (points.length <= 1) {
          mapController.move(center, 14);
        } else {
          mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.all(56),
              maxZoom: 16,
            ),
          );
        }
        return;
      }

      mapController.move(
        MapOperationalRegion.overviewCenter,
        MapOperationalRegion.overviewZoom,
      );
    });
  }

  IncidentForCards toCard(ParamedicoIncidentSummary s, String uid) {
    return IncidentForCardsMapper.fromSummary(
      summary: s,
      counts: IncidentForCardsMapper.countsFor(s.id, counts),
      currentUserId: uid,
    );
  }

  String get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<void> applyPendingFocus(BuildContext context) async {
    final id = pendingFocusId;
    if (id == null || id.isEmpty) return;
    final patientId = pendingFocusPatientId;
    pendingFocusId = null;
    pendingFocusPatientId = null;
    final generation = ++_focusGeneration;

    // Recién creado puede no haber llegado aún por tiempo real
    var found = _store.byId(id);
    if (found == null) {
      await _store.refresh();
      if (generation != _focusGeneration) return;
      found = _store.byId(id);
    }
    if (!context.mounted) return;

    if (found == null) {
      showAppSnackBar(
        context,
        'El incidente no está activo o no aparece en el mapa.',
        isError: true,
      );
      return;
    }

    final ParamedicoIncidentSummary inc = found;

    if (inc.latitude == null || inc.longitude == null) {
      showAppSnackBar(
        context,
        'Este incidente no tiene coordenadas para trazar ruta.',
        isError: true,
      );
      return;
    }

    if (patientId != null && patientId.isNotEmpty) {
      await focusIncidentForView(context, inc, highlightPatientId: patientId);
      return;
    }
    await onPinTap(context, inc);
  }

  Future<void> focusIncidentForView(
    BuildContext context,
    ParamedicoIncidentSummary inc, {
    String? highlightPatientId,
  }) async {
    selectedIncidentId = inc.id;
    forceShowPatientsIncidentId = inc.id;
    highlightedPatientId = highlightPatientId;
    routePoints = [];
    fullRoutePoints = [];
    followUser = false;
    notifyListeners();
    _fitIncidentAndPatients(inc);
  }

  void _fitIncidentAndPatients(ParamedicoIncidentSummary inc) {
    if (inc.latitude == null || inc.longitude == null) return;
    final center = LatLng(inc.latitude!, inc.longitude!);
    final patients = patientsByIncident[inc.id] ?? const [];
    final radius =
        radiusMetersByIncident[inc.id] ??
        MapIncidentCoverageService.radiusMeters(center, patients);
    final points = MapIncidentCoverageService.boundsPointsForIncident(
      incidentCenter: center,
      patients: patients,
      radiusMeters: radius,
    );
    _safeMapOp(() {
      if (points.length <= 1) {
        mapController.move(center, 16);
        return;
      }
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(72),
          maxZoom: 17,
        ),
      );
    });
  }

  List<LatLng> _overviewBoundsPoints(List<ParamedicoIncidentSummary> inRegion) {
    final points = <LatLng>[];
    for (final inc in inRegion) {
      final center = LatLng(inc.latitude!, inc.longitude!);
      final patients = patientsByIncident[inc.id] ?? const [];
      final radius =
          radiusMetersByIncident[inc.id] ??
          MapIncidentCoverageService.radiusMeters(center, patients);
      points.addAll(
        MapIncidentCoverageService.boundsPointsForIncident(
          incidentCenter: center,
          patients: patients,
          radiusMeters: radius,
        ),
      );
    }
    return points;
  }

  List<MapPatientPin> visiblePatientPins() {
    if (!_mapReady) return const [];
    final camera = mapController.camera;
    final center = camera.center;
    final zoom = camera.zoom;
    final visible = <MapPatientPin>[];
    for (final inc in mappableIncidents) {
      if (inc.latitude == null || inc.longitude == null) continue;
      final radius =
          radiusMetersByIncident[inc.id] ??
          MapIncidentCoverageService.defaultRadiusMeters;
      final incidentCenter = LatLng(inc.latitude!, inc.longitude!);
      final show = MapIncidentCoverageService.shouldShowPatients(
        zoom: zoom,
        cameraCenter: center,
        incidentCenter: incidentCenter,
        radiusMeters: radius,
        selectedIncidentId: selectedIncidentId,
        incidentId: inc.id,
        forceForIncident: forceShowPatientsIncidentId == inc.id,
      );
      if (!show) continue;
      visible.addAll(patientsByIncident[inc.id] ?? const []);
    }
    return visible;
  }

  List<({String incidentId, LatLng center, double radiusMeters})>
  visibleCoverageRings() {
    if (!_mapReady) return const [];
    final zoom = mapController.camera.zoom;
    final rings = <({String incidentId, LatLng center, double radiusMeters})>[];
    for (final inc in mappableIncidents) {
      if (inc.latitude == null || inc.longitude == null) continue;
      if (!MapIncidentCoverageService.shouldShowCoverageRing(
        zoom: zoom,
        selectedIncidentId: selectedIncidentId,
        incidentId: inc.id,
      )) {
        continue;
      }
      rings.add((
        incidentId: inc.id,
        center: LatLng(inc.latitude!, inc.longitude!),
        radiusMeters:
            radiusMetersByIncident[inc.id] ??
            MapIncidentCoverageService.defaultRadiusMeters,
      ));
    }
    return rings;
  }

  Future<void> onPinTap(
    BuildContext context,
    ParamedicoIncidentSummary inc,
  ) async {
    selectedIncidentId = inc.id;
    forceShowPatientsIncidentId = inc.id;
    routePoints = [];
    fullRoutePoints = [];
    followUser = false;
    notifyListeners();
    _startPositionStream();
    await loadRouteTo(inc, moveCamera: true, context: context);
    if (selectedIncidentId != inc.id) return;
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (selectedIncidentId != inc.id) return;
    enableFollowNavigation();
  }

  void clearSelection() {
    if (selectedIncidentId == null) return;
    _focusGeneration++;
    _stopPositionStream();
    selectedIncidentId = null;
    forceShowPatientsIncidentId = null;
    highlightedPatientId = null;
    routePoints = [];
    fullRoutePoints = [];
    followUser = false;
    userHeading = null;
    previousUserPosition = null;
    notifyListeners();
    goToRegionOverview();
  }

  void onMapBackgroundTap() {
    if (selectedIncidentId != null) clearSelection();
  }

  void enableFollowNavigation() {
    followUser = true;
    _startPositionStream();
    updateNavigationCamera(animated: false);
    notifyListeners();
  }

  void onMapPositionChanged(MapCamera camera, bool hasGesture) {
    var shouldNotify = false;
    if (hasGesture && followUser) {
      followUser = false;
      shouldNotify = true;
    }
    final epoch =
        (camera.zoom * 4).floor() +
        (camera.center.latitude * 1000).floor() +
        (camera.center.longitude * 1000).floor();
    if (_visibilityEpoch != epoch) {
      _visibilityEpoch = epoch;
      shouldNotify = true;
    }
    if (shouldNotify) notifyListeners();
  }

  void updateNavigationCamera({required bool animated}) {
    final pos = userPosition;
    if (pos == null || !followUser || !_mapReady) return;

    final rotation = MapNavigationHelpers.mapRotationForHeading(
      userHeading ?? 0,
    );
    const zoom = MapNavigationHelpers.navigationZoom;
    const offset = MapNavigationHelpers.userScreenOffset;

    final impl = mapController;
    if (impl is! MapControllerImpl) {
      mapController.moveAndRotate(pos, zoom, rotation);
      return;
    }

    if (animated) {
      impl.moveAndRotateAnimatedRaw(
        pos,
        zoom,
        rotation,
        offset: offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        hasGesture: false,
        source: MapEventSource.mapController,
      );
    } else {
      impl.moveAndRotateRaw(
        pos,
        zoom,
        rotation,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
      );
    }
  }

  Future<void> loadRouteTo(
    ParamedicoIncidentSummary inc, {
    bool moveCamera = true,
    BuildContext? context,
  }) async {
    if (inc.latitude == null || inc.longitude == null) return;
    var from = userPosition;
    if (from == null) {
      final pos = await IncidentLocationService.getCurrentPosition();
      if (pos != null) {
        from = LatLng(pos.lat, pos.lng);
        userPosition = from;
        notifyListeners();
      }
    }
    if (from == null) {
      if (context != null && context.mounted) {
        showAppSnackBar(
          context,
          IncidentLocationService.errorMessageForNullResult() ??
              'Sin ubicación GPS.',
          isError: true,
        );
      }
      return;
    }

    routing = true;
    notifyListeners();

    final points = await _routeService.fetchDrivingRoute(
      fromLat: from.latitude,
      fromLng: from.longitude,
      toLat: inc.latitude!,
      toLng: inc.longitude!,
    );

    routing = false;
    fullRoutePoints = points;
    routePoints = userPosition != null && points.length >= 2
        ? MapNavigationHelpers.trimRouteAhead(
            route: points,
            user: userPosition!,
          )
        : points;
    notifyListeners();

    if (moveCamera && points.length >= 2 && !followUser) {
      final bounds = LatLngBounds.fromPoints(points);
      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    }
  }

  Future<void> centerOnUser(BuildContext context) async {
    final pos = await IncidentLocationService.getCurrentPosition();
    if (!context.mounted) return;
    if (pos == null) {
      showAppSnackBar(
        context,
        IncidentLocationService.errorMessageForNullResult() ??
            'No se pudo obtener GPS.',
        isError: true,
      );
      return;
    }
    final p = LatLng(pos.lat, pos.lng);
    userPosition = p;
    notifyListeners();
    final sel = selectedIncident;
    if (sel != null) {
      enableFollowNavigation();
      await loadRouteTo(sel, moveCamera: false);
    } else {
      _safeMapOp(() => mapController.move(p, 15));
    }
  }

  void openIncidentDetail(BuildContext context, String incidentId) {
    pushParamedicoFullScreen(context, '/paramedico/incident/$incidentId');
  }

  void openPatientDetail(BuildContext context, String patientId) {
    pushParamedicoFullScreen(context, '/paramedico/patient/$patientId');
  }
}
