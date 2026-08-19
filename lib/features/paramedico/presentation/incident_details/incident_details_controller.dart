import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_metadata_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_view_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/routing/patient_registration_route_seed.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum IncidentDetailsShellMode { loading, error, ready }

// Orquestador de detalle de incidente: carga datos, filtros, navegación y mutaciones
class IncidentDetailsController extends ChangeNotifier {
  IncidentDetailsController({
    required this.incidentId,
    ParamedicoIncidentsRepository? repository,
    TextEditingController? searchController,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       searchController = searchController ?? TextEditingController();

  final String incidentId;
  final ParamedicoIncidentsRepository _repo;
  final TextEditingController searchController;
  final ImagePicker _picker = ImagePicker();

  static const contentTabs = [
    IncidentTabType.lista,
    IncidentTabType.mapa,
    IncidentTabType.fotos,
    IncidentTabType.estadisticas,
  ];

  ParamedicoIncidentSummary? incident;
  List<ParamedicoPatientRow> patients = [];
  bool loading = true;
  String? error;
  String? creatorName;
  IncidentTabType activeTab = IncidentTabType.lista;
  String patientQuery = '';
  PatientTriageFilter triageFilter = PatientTriageFilter.todos;
  PatientSortOption sortOption = PatientSortOption.recent;

  String get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  bool get canEditIncident {
    final inc = incident;
    final uid = currentUserId;
    return inc != null && uid.isNotEmpty && inc.createdBy == uid;
  }

  IncidentDetailsShellMode get shellMode {
    if (loading) return IncidentDetailsShellMode.loading;
    if (error != null || incident == null) {
      return IncidentDetailsShellMode.error;
    }
    return IncidentDetailsShellMode.ready;
  }

  String get routeBase => '/paramedico/incident/$incidentId';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void resetFilters() {
    searchController.clear();
    patientQuery = '';
    triageFilter = PatientTriageFilter.todos;
    sortOption = PatientSortOption.recent;
    activeTab = IncidentTabType.lista;
  }

  Future<void> load() async {
    if (!SupabaseEnv.isConfigured) {
      loading = false;
      error = 'Supabase no configurado.';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      final inc = await _repo.getIncident(incidentId);
      final pts = await _repo.listPatientsForIncident(incidentId);
      String? creator;
      if (inc != null && inc.createdBy.isNotEmpty) {
        creator = await _repo.getProfileFullName(inc.createdBy);
      }
      incident = inc;
      patients = pts;
      creatorName = creator;
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  void setActiveTab(IncidentTabType tab) {
    activeTab = tab;
    notifyListeners();
  }

  void setPatientQuery(String value) {
    patientQuery = value;
    notifyListeners();
  }

  void setTriageFilter(PatientTriageFilter filter) {
    triageFilter = filter;
    notifyListeners();
  }

  void setSortOption(PatientSortOption option) {
    sortOption = option;
    notifyListeners();
  }

  List<ParamedicoPatientRow> get filteredPatients =>
      ParamedicoCatalogMappers.filterAndSortPatients(
        patients: patients,
        query: patientQuery,
        triageFilter: triageFilter,
        sortOption: sortOption,
      );

  IncidentHeaderData headerData(BuildContext context) {
    final inc = incident!;
    return IncidentDetailsViewMapper.headerData(
      incident: inc,
      patients: patients,
      isEditable: canEditIncident,
      onShowMapTap: () => openInteractiveMap(context),
      onEditLocationTap: () => unawaited(editIncidentCoords(context)),
      onEditTitleTap: () => unawaited(editIncidentTitle(context)),
    );
  }

  IncidentMetadataData metadataData() {
    return IncidentDetailsViewMapper.metadataData(
      creatorName: creatorName,
      incident: incident!,
    );
  }

  IncidentTabSelectorData tabSelectorData() {
    return IncidentTabSelectorData(
      activeTab: activeTab,
      availableTabs: contentTabs,
      onTabChanged: setActiveTab,
    );
  }

  String listEmptyMessage() {
    return IncidentDetailsViewMapper.listEmptyMessage(
      allPatients: patients,
      filtered: filteredPatients,
    );
  }

  List<PatientCardData> patientCards(BuildContext context) {
    final inc = incident!;
    final gps = IncidentPresentationFormatters.incidentGpsLabel(inc);
    return IncidentDetailsViewMapper.patientCards(
      filtered: filteredPatients,
      coordinatesLabel: gps,
      onPatientTap: (id) =>
          pushParamedicoFullScreen(context, '/paramedico/patient/$id'),
    );
  }

  void leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/paramedico/incidentes');
    }
  }

  Future<void> confirmClose(BuildContext context) async {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes cerrar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar incidente'),
        content: const Text('¿Marcar este incidente como cerrado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await _repo.closeIncident(incidentId);
      if (!context.mounted) return;
      showAppSnackBar(context, 'Incidente cerrado.');
      context.go('/paramedico/home');
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, '$e', isError: true);
    }
  }

  Future<void> openTriageAndRefresh(BuildContext context) async {
    await pushParamedicoFullScreen(context, '$routeBase/triage');
    await load();
  }

  Future<void> openRegisterAndRefresh(BuildContext context) async {
    final i = incident;
    if (i == null) return;
    final Object? extra = i.latitude != null && i.longitude != null
        ? PatientRegistrationRouteSeed(
            latitude: i.latitude!,
            longitude: i.longitude!,
          )
        : null;
    await pushParamedicoFullScreen(
      context,
      '$routeBase/register',
      extra: extra,
    );
    await load();
  }

  Future<void> openIncidentOnMap(BuildContext context) async {
    final inc = incident;
    if (inc == null) return;
    if (!IncidentPresentationFormatters.hasIncidentLocation(inc)) {
      showAppSnackBar(
        context,
        'Este incidente no tiene coordenadas. Use Editar para registrarlas.',
        isError: true,
      );
      return;
    }
    await IncidentLocationMapDialog.showPreview(
      context,
      lat: inc.latitude!,
      lng: inc.longitude!,
      title: 'Ubicación del incidente',
    );
  }

  Future<void> editIncidentCoords(BuildContext context) async {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes editar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return;
    }
    final inc = incident;
    if (inc == null) return;
    final coords = IncidentPresentationFormatters.incidentMapCoords(inc);
    final r = await IncidentLocationMapDialog.show(
      context,
      lat: coords.$1,
      lng: coords.$2,
      title: 'Ubicación del incidente',
    );
    if (r == null) return;
    try {
      await _repo.updateIncidentLocation(
        incidentId: incidentId,
        lat: r.latitude,
        lng: r.longitude,
      );
      if (!context.mounted) return;
      showAppSnackBar(context, 'Ubicación del incidente actualizada.');
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  Future<void> editIncidentTitle(BuildContext context) async {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes editar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return;
    }
    final inc = incident;
    if (inc == null) return;
    final controller = TextEditingController(text: inc.generatedTitle);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Editar título del incidente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Título del incidente'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(
              'Guardar',
              style: TextStyle(color: Color(0xFFCE1125)),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nextTitle == null) return;
    final trimmed = nextTitle.trim();
    if (trimmed.isEmpty) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'El título no puede quedar vacío.',
          isError: true,
        );
      }
      return;
    }
    try {
      await _repo.updateIncidentTitle(incidentId: incidentId, title: trimmed);
      if (!context.mounted) return;
      showAppSnackBar(context, 'Título del incidente actualizado.');
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  Future<void> saveIncidentDescription(
    BuildContext context,
    String description,
  ) async {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes editar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return;
    }
    final trimmed = description.trim();
    try {
      await _repo.updateIncidentDescription(
        incidentId: incidentId,
        description: trimmed.isEmpty ? null : trimmed,
      );
      await load();
      if (!context.mounted) return;
      showAppSnackBar(context, 'Descripción del incidente actualizada.');
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  void showIncidentImageSourceDialog(BuildContext context) {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes editar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFCE1125)),
              title: const Text('Tomar foto con la cámara'),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(addIncidentPhoto(context, ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFCE1125),
              ),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(addIncidentPhoto(context, ImageSource.gallery));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addIncidentPhoto(
    BuildContext context,
    ImageSource source,
  ) async {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes editar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return;
    }
    final inc = incident;
    if (inc == null) return;
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;
      final nextPhotos = List<String>.from(inc.photoPaths)..add(image.path);
      await _repo.updateIncidentPhotoPaths(
        incidentId: incidentId,
        photoPaths: nextPhotos,
      );
      if (!context.mounted) return;
      showAppSnackBar(context, 'Foto agregada al incidente.');
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  Future<void> removeIncidentPhotoAt(BuildContext context, int index) async {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes editar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return;
    }
    final inc = incident;
    if (inc == null || index < 0 || index >= inc.photoPaths.length) return;
    final nextPhotos = List<String>.from(inc.photoPaths)..removeAt(index);
    try {
      await _repo.updateIncidentPhotoPaths(
        incidentId: incidentId,
        photoPaths: nextPhotos,
      );
      if (!context.mounted) return;
      showAppSnackBar(context, 'Foto eliminada del incidente.');
      await load();
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  void openInteractiveMap(BuildContext context) {
    final inc = incident;
    if (inc == null) return;
    final returnTo = Uri.encodeComponent('/paramedico/incident/$incidentId');
    pushParamedicoFullScreen(
      context,
      '/paramedico/mapa-interactivo?focus=${inc.id}&returnTo=$returnTo',
    );
  }
}
