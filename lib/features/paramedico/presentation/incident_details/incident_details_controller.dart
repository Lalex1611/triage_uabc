import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/map/map_patient_pin.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_view_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_flow.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_incidents_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

enum IncidentDetailsShellMode { loading, error, ready }

// Orquestador de detalle de incidente: carga datos, filtros, navegación y mutaciones
class IncidentDetailsController extends ChangeNotifier {
  IncidentDetailsController({
    required this.incidentId,
    ParamedicoIncidentsRepository? repository,
  }) : _repo = repository ?? ParamedicoIncidentsRepository();

  final String incidentId;
  final ParamedicoIncidentsRepository _repo;
  final ImagePicker _picker = ImagePicker();

  static const contentTabs = [
    IncidentTabType.lista,
    IncidentTabType.mapa,
    IncidentTabType.fotos,
    IncidentTabType.estadisticas,
  ];

  ParamedicoIncidentSummary? incident;
  List<ParamedicoPatientRow> patients = [];
  List<MapPatientPin> mapPatients = [];
  Map<String, String> photoUrls = {};
  bool uploadingPhoto = false;
  bool _disposed = false;
  bool loading = true;
  String? error;
  String? creatorName;
  IncidentTabType activeTab = IncidentTabType.lista;
  PatientTriageFilter triageFilter = PatientTriageFilter.todos;

  String get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  bool get canEditIncident {
    final inc = incident;
    final uid = currentUserId;
    return inc != null && uid.isNotEmpty && inc.createdBy == uid;
  }

  bool get canCloseIncident => canEditIncident && incident?.status != 'cerrado';

  IncidentDetailsShellMode get shellMode {
    if (loading) return IncidentDetailsShellMode.loading;
    if (error != null || incident == null) {
      return IncidentDetailsShellMode.error;
    }
    return IncidentDetailsShellMode.ready;
  }

  String get routeBase => '/paramedico/incident/$incidentId';

  List<ImageProvider> get incidentPhotos =>
      IncidentDetailsViewMapper.photoImages(
        paths: incident?.photoPaths ?? const [],
        signedUrls: photoUrls,
      );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Una subida lenta puede terminar cuando el usuario ya salió de la pantalla
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Con [showLoader] en `false` actualiza sin sustituir la pantalla por el cargador
  Future<void> load({bool showLoader = true}) async {
    if (!SupabaseEnv.isConfigured) {
      loading = false;
      error = 'Supabase no configurado.';
      notifyListeners();
      return;
    }
    if (showLoader) loading = true;
    error = null;
    notifyListeners();

    try {
      final inc = await _repo.getIncident(incidentId);
      final pts = await _repo.listPatientsForIncident(incidentId);
      final lat = inc?.latitude;
      final lng = inc?.longitude;
      final pins = lat != null && lng != null
          ? await _loadMapPatients(LatLng(lat, lng))
          : <MapPatientPin>[];
      final urls = await _signPhotos(
        inc?.photoPaths ?? const [],
        known: showLoader ? const {} : photoUrls,
      );
      String? creator;
      if (inc != null && inc.createdBy.isNotEmpty) {
        creator = await _repo.getProfileFullName(inc.createdBy);
      }
      incident = inc;
      patients = pts;
      mapPatients = pins;
      photoUrls = urls;
      creatorName = creator;
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  /// Si falla, el mapa marca solo el punto del incidente y el resto sigue visible
  Future<List<MapPatientPin>> _loadMapPatients(LatLng center) async {
    try {
      return await _repo.listMapPatientPinsForIncidents(
        [incidentId],
        incidentCentersById: {incidentId: center},
      );
    } catch (e) {
      debugPrint('No se pudieron cargar los pacientes del mapa: $e');
      return [];
    }
  }

  /// Conserva los enlaces [known] para que las fotos ya visibles no parpadeen.
  /// Si falla, las fotos muestran su ícono y el resto de la pantalla sigue visible
  Future<Map<String, String>> _signPhotos(
    List<String> paths, {
    required Map<String, String> known,
  }) async {
    try {
      return {
        ...known,
        ...await _repo.signIncidentPhotos(
          paths.where((path) => !known.containsKey(path)),
        ),
      };
    } catch (e) {
      debugPrint('No se pudieron firmar las fotos del incidente: $e');
      return known;
    }
  }

  /// Quitarla de Storage no debe impedir el resultado: la foto ya no está en el incidente
  Future<void> _discardStoredPhoto(String path) async {
    try {
      await _repo.deleteIncidentPhoto(path);
    } catch (e) {
      debugPrint('No se pudo borrar la foto $path: $e');
    }
  }

  void setActiveTab(IncidentTabType tab) {
    activeTab = tab;
    notifyListeners();
  }

  void setTriageFilter(PatientTriageFilter filter) {
    triageFilter = filter;
    notifyListeners();
  }

  List<ParamedicoPatientRow> get filteredPatients =>
      ParamedicoCatalogMappers.filterAndSortPatients(
        patients: patients,
        triageFilter: triageFilter,
        sortOption: PatientSortOption.recent,
      );

  IncidentHeaderData headerData() {
    return IncidentDetailsViewMapper.headerData(
      incident: incident!,
      patients: patients,
      creatorName: creatorName,
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
    return IncidentDetailsViewMapper.patientCards(
      filtered: filteredPatients,
      onPatientTap: (id) => openPatient(context, id),
    );
  }

  void openPatient(BuildContext context, String patientId) {
    pushParamedicoFullScreen(context, '/paramedico/patient/$patientId');
  }

  void leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/paramedico');
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

    final confirmed = await showTriageConfirm(
      context,
      icon: const TriageMessageIcon(
        TriageIcons.reject,
        tone: TriageTone.danger,
      ),
      title: '¿Cerrar el incidente?',
      message: IncidentDetailsViewMapper.closeIncidentMessage(
        incidentId: incidentId,
        patientCount: patients.length,
      ),
      confirmLabel: 'Sí, cerrar incidente',
      confirmVariant: TriageButtonVariant.danger,
    );

    if (!confirmed || !context.mounted) return;

    try {
      await _repo.closeIncident(incidentId);
      // Sin esperar al aviso del tiempo real: el mapa debe dejar de mostrarlo ya
      unawaited(ParamedicoIncidentsStore.instance.refresh());
      if (!context.mounted) return;
      showAppSnackBar(context, 'Incidente cerrado.');
      context.go('/paramedico/mapa');
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, '$e', isError: true);
    }
  }

  /// B11: abre el panel de registro y actualiza el incidente tras cada paciente
  Future<void> openRegistration(BuildContext context) {
    final header = headerData();
    return startPatientIntake(
      context,
      incidentId: incidentId,
      subtitle: '${header.id} · ${header.title}',
      onPatientsChanged: () => unawaited(load(showLoader: false)),
    );
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
    Future.delayed(const Duration(milliseconds: 300), () {
      controller.dispose();
    }); // Se edita el titulo del incidente
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
      await load(showLoader: false);
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
    showTriageSheet<void>(
      context,
      title: 'Añadir fotografía',
      showClose: false,
      builder: (sheetContext) {
        void pick(ImageSource source) {
          Navigator.pop(sheetContext);
          unawaited(addIncidentPhoto(context, source));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TriageOptionRow(
              icon: TriageIcons.camera,
              title: 'Tomar foto',
              detail: 'Usa la cámara del teléfono',
              onTap: () => pick(ImageSource.camera),
            ),
            TriageOptionRow(
              icon: TriageIcons.image,
              title: 'Elegir de la galería',
              detail: 'Selecciona una foto guardada',
              onTap: () => pick(ImageSource.gallery),
            ),
          ],
        );
      },
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
    if (inc == null || uploadingPhoto) return;
    String? storedPath;
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (image == null) return;
      uploadingPhoto = true;
      notifyListeners();
      storedPath = await _repo.uploadIncidentPhoto(
        incidentId: incidentId,
        localPath: image.path,
      );
      await _repo.updateIncidentPhotoPaths(
        incidentId: incidentId,
        photoPaths: [...inc.photoPaths, storedPath],
      );
      await load(showLoader: false);
      if (context.mounted) {
        showAppSnackBar(context, 'Foto agregada al incidente.');
      }
    } catch (e) {
      debugPrint('No se pudo subir la foto del incidente: $e');
      if (storedPath != null) unawaited(_discardStoredPhoto(storedPath));
      if (context.mounted) {
        showAppSnackBar(
          context,
          'No se pudo subir la foto. Revisa la conexión e inténtalo de nuevo.',
          isError: true,
        );
      }
    } finally {
      uploadingPhoto = false;
      notifyListeners();
    }
  }

  /// Pide confirmación y devuelve si la foto se eliminó
  Future<bool> confirmRemoveIncidentPhoto(
    BuildContext context,
    int index,
  ) async {
    if (!canEditIncident) {
      showAppSnackBar(
        context,
        'Solo puedes editar incidentes asignados a tu cuenta.',
        isError: true,
      );
      return false;
    }
    final inc = incident;
    if (inc == null || index < 0 || index >= inc.photoPaths.length) {
      return false;
    }
    final confirmed = await showTriageConfirm(
      context,
      icon: const TriageMessageIcon(TriageIcons.trash, tone: TriageTone.danger),
      title: '¿Eliminar esta fotografía?',
      message:
          'No se puede recuperar. El resto de la información del incidente no cambia.',
      confirmLabel: 'Eliminar',
      confirmVariant: TriageButtonVariant.danger,
    );
    if (!confirmed) return false;

    final removed = inc.photoPaths[index];
    final nextPhotos = List<String>.from(inc.photoPaths)..removeAt(index);
    try {
      await _repo.updateIncidentPhotoPaths(
        incidentId: incidentId,
        photoPaths: nextPhotos,
      );
      unawaited(_discardStoredPhoto(removed));
      await load(showLoader: false);
      if (context.mounted) {
        showAppSnackBar(context, 'Foto eliminada del incidente.');
      }
      return true;
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
      return false;
    }
  }
}
