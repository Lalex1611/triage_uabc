import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_title_formatter.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_notifications_action.dart';

class CreateIncidentController extends ChangeNotifier {
  CreateIncidentController({
    ParamedicoIncidentsRepository? repository,
    ParamedicNotificationsRepository? notificationsRepository,
    TextEditingController? descriptionController,
    ImagePicker? picker,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       _notificationsRepo =
           notificationsRepository ?? ParamedicNotificationsRepository(),
       descriptionController = descriptionController ?? TextEditingController(),
       _picker = picker ?? ImagePicker();

  final ParamedicoIncidentsRepository _repo;
  final ParamedicNotificationsRepository _notificationsRepo;
  final TextEditingController descriptionController;
  final ImagePicker _picker;

  late final String draftIdLabel = _buildDraftIdLabel();

  String? emergencyTypeId = EmergencyCatalog.defaultTypeId;
  double lat = 32.5027;
  double lng = -117.00371;
  DateTime capturedAt = DateTime.now();
  bool submitting = false;
  bool refreshingGps = false;
  String previewTitle = 'Generando título…';
  String? customTitle;
  bool refreshingTitle = false;
  final List<String> photos = [];
  int unreadNotifications = 0;

  String get displayTitle => customTitle ?? previewTitle;

  String _buildDraftIdLabel() {
    final raw = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = raw.length <= 6 ? raw : raw.substring(raw.length - 6);
    return 'INC-${suffix.toUpperCase()}';
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> refreshPreviewTitle() async {
    if (refreshingTitle) return;
    refreshingTitle = true;
    notifyListeners();
    try {
      previewTitle = await IncidentTitleFormatter.resolveTitle(
        customTitle: null,
        atLocal: capturedAt,
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      previewTitle = IncidentTitleFormatter.formatAuto(
        atLocal: capturedAt,
        locationKey: '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      );
    } finally {
      refreshingTitle = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    unreadNotifications = await ParamedicoNotificationsAction.unreadCount(
      _notificationsRepo,
    );
    notifyListeners();
  }

  Future<void> editTitle(BuildContext context) async {
    final controller = TextEditingController(text: displayTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Editar título del incidente',
          style: Theme.of(ctx).textTheme.titleMedium,
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nuevo título…'),
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
    if (newTitle == null) return;
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) {
      customTitle = null;
      await refreshPreviewTitle();
    } else {
      customTitle = trimmed;
      notifyListeners();
    }
  }

  String mapEmergencyForRpc() {
    final id = emergencyTypeId;
    if (id == null || id.isEmpty) {
      throw Exception('Selecciona un tipo de emergencia.');
    }
    if (id == 'OTRO') return 'otro';
    return id;
  }

  void setEmergencyType(String? id) {
    emergencyTypeId = id;
    notifyListeners();
  }

  Future<void> refreshGpsFromDevice(
    BuildContext context, {
    bool silent = false,
  }) async {
    if (refreshingGps) return;
    refreshingGps = true;
    notifyListeners();
    try {
      final p = await IncidentLocationService.getCurrentPosition();
      if (p != null) {
        lat = p.lat;
        lng = p.lng;
        capturedAt = DateTime.now();
        if (customTitle == null) {
          unawaited(refreshPreviewTitle());
        }
      } else if (!silent && context.mounted) {
        showAppSnackBar(
          context,
          IncidentLocationService.errorMessageForNullResult()!,
          isError: true,
        );
      }
    } catch (e) {
      if (!silent && context.mounted) {
        showAppSnackBar(context, 'No se pudo leer el GPS: $e', isError: true);
      }
    } finally {
      refreshingGps = false;
      notifyListeners();
    }
  }

  Future<void> openLocationMap(BuildContext context) async {
    final result = await IncidentLocationMapDialog.show(
      context,
      lat: lat,
      lng: lng,
    );
    if (result == null) return;
    lat = result.latitude;
    lng = result.longitude;
    capturedAt = DateTime.now();
    if (customTitle == null) {
      await refreshPreviewTitle();
    } else {
      notifyListeners();
    }
  }

  Future<void> openManualCoords(BuildContext context) async {
    final latCtrl = TextEditingController(text: lat.toString());
    final lngCtrl = TextEditingController(text: lng.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coordenadas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(labelText: 'Latitud'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            TextField(
              controller: lngCtrl,
              decoration: const InputDecoration(labelText: 'Longitud'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final la = double.tryParse(latCtrl.text.replaceAll(',', '.'));
      final ln = double.tryParse(lngCtrl.text.replaceAll(',', '.'));
      if (la != null && ln != null) {
        lat = la;
        lng = ln;
        capturedAt = DateTime.now();
        if (customTitle == null) {
          unawaited(refreshPreviewTitle());
        } else {
          notifyListeners();
        }
      }
    }
    latCtrl.dispose();
    lngCtrl.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        photos.add(image.path);
        notifyListeners();
      }
    } catch (_) {}
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= photos.length) return;
    photos.removeAt(index);
    notifyListeners();
  }

  void showImageSourceDialog(BuildContext context) {
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
                pickImage(ImageSource.camera);
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
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submit(BuildContext context) async {
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return;
    }
    submitting = true;
    notifyListeners();
    try {
      final type = mapEmergencyForRpc();
      final title = await IncidentTitleFormatter.resolveTitle(
        customTitle: customTitle,
        atLocal: capturedAt,
        lat: lat,
        lng: lng,
      );
      final id = await _repo.createIncident(
        title: title,
        emergencyType: type,
        lng: lng,
        lat: lat,
      );
      final desc = descriptionController.text.trim();
      if (desc.isNotEmpty) {
        await _repo.updateIncidentDescription(
          incidentId: id,
          description: desc,
        );
      }
      if (photos.isNotEmpty) {
        await _repo.updateIncidentPhotoPaths(
          incidentId: id,
          photoPaths: List<String>.from(photos),
        );
      }
      if (!context.mounted) return;
      showAppSnackBar(context, 'Incidente creado.');
      context.go('/paramedico/incidentes');
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Salir de la cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AuthGate.instance.signOut();
      if (context.mounted) context.go('/auth');
    }
  }

  Future<void> openNotifications(BuildContext context) async {
    await ParamedicoNotificationsAction.open(
      context,
      repository: _notificationsRepo,
      onUnreadChanged: (count) {
        unreadNotifications = count;
        notifyListeners();
      },
    );
  }
}
