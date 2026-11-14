import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/core/util/map_launcher.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/domain/services/map_incident_coverage_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_geocoding_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/services/map_operational_region.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_incidents_store.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_notifications_action.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Filtros del mapa en vivo (B01)
enum MapIncidentFilter { mine, all, nearby }

// Orquestador del mapa interactivo de incidentes: carga, filtros, búsqueda y
// selección de pin. La ruta al incidente la da Google Maps
class ParamedicoMapController extends ChangeNotifier {
  ParamedicoMapController({
    this.initialFocusIncidentId,
    this.initialFocusPatientId,
    ParamedicoIncidentsRepository? repository,
    ParamedicNotificationsRepository? notificationsRepository,
    MapGeocodingService? geocodingService,
    MapController? mapController,
    TextEditingController? searchController,
    ParamedicoIncidentsStore? store,
  }) : _store = store ?? ParamedicoIncidentsStore.instance,
       _repo = repository ?? ParamedicoIncidentsRepository(),
       _notificationsRepo =
           notificationsRepository ?? ParamedicNotificationsRepository(),
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

  /// Incidente elegido: su panel abajo (B03)
  String? selectedIncidentId;

  /// Se llegó desde la ficha de este paciente: "Volver al paciente" la reabre
  String? returnToPatientId;
  LatLng? userPosition;
  MapIncidentFilter filter = MapIncidentFilter.all;
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

  // Las cargas en curso pueden terminar con la pantalla ya cerrada
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(_onStoreChanged);
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
      _dropSelection();
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

    focusIncidentForView(
      inc,
      highlightPatientId: patientId != null && patientId.isNotEmpty
          ? patientId
          : null,
    );
  }

  /// Elige el incidente (vista previa, sin ruta) y lo encuadra con sus
  /// pacientes. Con [highlightPatientId] se llegó desde su ficha
  void focusIncidentForView(
    ParamedicoIncidentSummary inc, {
    String? highlightPatientId,
  }) {
    selectedIncidentId = inc.id;
    forceShowPatientsIncidentId = inc.id;
    highlightedPatientId = highlightPatientId;
    returnToPatientId = highlightPatientId;
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

  /// Tocar un incidente lo elige y muestra su panel (B03), sin mover el mapa
  void onPinTap(ParamedicoIncidentSummary inc) {
    if (selectedIncidentId != inc.id) {
      highlightedPatientId = null;
      returnToPatientId = null;
    }
    selectedIncidentId = inc.id;
    forceShowPatientsIncidentId = inc.id;
    notifyListeners();
  }

  /// "Cómo llegar": la ruta, el tiempo con tráfico y la navegación los da
  /// Google Maps, que sale desde la posición actual del usuario
  Future<void> openDirections(BuildContext context) async {
    final inc = selectedIncident;
    if (inc == null || inc.latitude == null || inc.longitude == null) return;
    final opened = await launchDirectionsExternal(
      inc.latitude!,
      inc.longitude!,
    );
    if (opened || !context.mounted) return;
    showAppSnackBar(context, 'No se pudo abrir Google Maps.', isError: true);
  }

  /// Reabre la ficha desde la que se llegó al mapa
  void returnToPatient(BuildContext context) {
    final id = returnToPatientId;
    if (id == null) return;
    clearSelection();
    openPatientDetail(context, id);
  }

  /// Botón atrás del sistema con un incidente elegido: vuelve a la ficha del
  /// paciente (si se vino de ella) o suelta el incidente
  void back(BuildContext context) {
    if (returnToPatientId != null) {
      returnToPatient(context);
    } else {
      clearSelection();
    }
  }

  void clearSelection() {
    if (selectedIncidentId == null) return;
    _dropSelection();
    notifyListeners();
    goToRegionOverview();
  }

  void _dropSelection() {
    _focusGeneration++;
    selectedIncidentId = null;
    forceShowPatientsIncidentId = null;
    highlightedPatientId = null;
    returnToPatientId = null;
  }

  void onMapBackgroundTap() {
    if (selectedIncidentId != null) clearSelection();
  }

  void onMapPositionChanged(MapCamera camera, bool hasGesture) {
    final epoch =
        (camera.zoom * 4).floor() +
        (camera.center.latitude * 1000).floor() +
        (camera.center.longitude * 1000).floor();
    if (_visibilityEpoch != epoch) {
      _visibilityEpoch = epoch;
      notifyListeners();
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
    _safeMapOp(() => mapController.move(p, 15));
  }

  void openIncidentDetail(BuildContext context, String incidentId) {
    pushParamedicoFullScreen(context, '/paramedico/incident/$incidentId');
  }

  void openPatientDetail(BuildContext context, String patientId) {
    pushParamedicoFullScreen(context, '/paramedico/patient/$patientId');
  }
}
