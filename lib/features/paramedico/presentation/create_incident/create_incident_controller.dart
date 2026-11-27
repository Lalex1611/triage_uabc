import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/geo/nominatim_reverse_geocode.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';

class CreateIncidentController extends ChangeNotifier {
  CreateIncidentController({
    ParamedicoIncidentsRepository? repository,
    TextEditingController? descriptionController,
    ImagePicker? picker,
    Future<String?> Function(double lat, double lng)? placeLookup,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       descriptionController = descriptionController ?? TextEditingController(),
       _picker = picker ?? ImagePicker(),
       _placeLookup = placeLookup ?? NominatimReverseGeocode.shortPlaceLabel;

  final ParamedicoIncidentsRepository _repo;
  final TextEditingController descriptionController;
  final ImagePicker _picker;
  final Future<String?> Function(double lat, double lng) _placeLookup;
  int _placeRequest = 0;

  late final String draftIdLabel = _buildDraftIdLabel();

  String? emergencyTypeId = EmergencyCatalog.defaultTypeId;
  double lat = 32.5027;
  double lng = -117.00371;
  DateTime capturedAt = DateTime.now();
  bool submitting = false;
  bool refreshingGps = false;

  /// Dirección corta del punto elegido; null si no se encontró
  String? placeLabel;
  bool refreshingPlace = false;
  bool locationConfirmed = false;
  String? locationError;
  final List<String> photos = [];

  /// El incidente se titula con su categoría
  String get title => EmergencyCatalog.nameFor(mapEmergencyForRpc());
  bool get canSubmit => locationConfirmed && !submitting;

  String _buildDraftIdLabel() {
    final raw = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = raw.length <= 6 ? raw : raw.substring(raw.length - 6);
    return 'INC-${suffix.toUpperCase()}';
  }

  @override
  void dispose() {
    _placeRequest++; // la búsqueda pendiente ya no avisa a nadie
    descriptionController.dispose();
    super.dispose();
  }

  /// Busca la dirección del punto actual. Cada punto elegido lanza su propia
  /// búsqueda y solo se aplica la del último
  Future<void> refreshPlace() async {
    final request = ++_placeRequest;
    refreshingPlace = true;
    notifyListeners();
    final label = await _placeLookup(lat, lng);
    if (request != _placeRequest) return;
    placeLabel = label;
    refreshingPlace = false;
    notifyListeners();
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
        locationConfirmed = true;
        locationError = null;
        capturedAt = DateTime.now();
        unawaited(refreshPlace());
      } else {
        // Si ya confirmó una ubicación manualmente, no se pisa con el error
        if (!locationConfirmed) {
          locationError = IncidentLocationService.errorMessageForNullResult();
        }
        if (!silent && context.mounted) {
          showAppSnackBar(
            context,
            IncidentLocationService.errorMessageForNullResult()!,
            isError: true,
          );
        }
      }
    } catch (e) {
      if (!locationConfirmed) {
        locationError = 'No se pudo leer el GPS: $e';
      }
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
    locationConfirmed = true;
    locationError = null;
    capturedAt = DateTime.now();
    await refreshPlace();
  }

  Future<void> pickImage(ImageSource source) async {
    if (submitting) return;
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null && !submitting) {
        photos.add(image.path);
        notifyListeners();
      }
    } catch (_) {}
  }

  void removePhotoAt(int index) {
    if (submitting) return;
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

  /// Crea el incidente y devuelve su id (null si falló). Ya no navega: lo hace
  /// quien llamó (la hoja de nuevo incidente)
  Future<String?> submit(BuildContext context) async {
    if (submitting) return null;
    if (!locationConfirmed) {
      showAppSnackBar(
        context,
        'Confirma la ubicación antes de crear el incidente.',
        isError: true,
      );
      return null;
    }
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return null;
    }
    submitting = true;
    notifyListeners();
    try {
      final type = mapEmergencyForRpc();
      if (_repo.usesLocalCaptures) {
        final id = await _repo.captureIncident(
          title: title,
          emergencyType: type,
          lat: lat,
          lng: lng,
          description: descriptionController.text.trim(),
          photos: List<String>.of(photos),
        );
        if (context.mounted) {
          showAppSnackBar(context, 'Guardado en este teléfono');
        }
        return id;
      }
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
      // El incidente ya existe: si fallan las fotos no se debe volver a crear
      var photosUploaded = true;
      final photosToUpload = List<String>.of(photos);
      if (photosToUpload.isNotEmpty) {
        try {
          for (final photo in photosToUpload) {
            final path = await _repo.uploadIncidentPhoto(
              incidentId: id,
              localPath: photo,
            );
            await _repo.changeIncidentPhotoPath(
              incidentId: id,
              path: path,
              remove: false,
            );
          }
        } catch (e) {
          debugPrint('No se pudieron subir las fotos del incidente: $e');
          photosUploaded = false;
        }
      }
      if (context.mounted) {
        showAppSnackBar(
          context,
          photosUploaded
              ? 'Incidente creado.'
              : 'Incidente creado, pero no se pudieron subir las fotos. '
                    'Añádelas desde el incidente.',
          isError: !photosUploaded,
        );
      }
      return id;
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
      return null;
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
}
