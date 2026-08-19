import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_body_kind.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_result.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_display_name_formatter.dart';

// Orquestador de START triage: asignación rápida, protocolo guiado y registro continuo sin salir de START
class StartTriageController extends ChangeNotifier {
  StartTriageController({
    this.incidentId,
    StartTriageTabOption initialTab = StartTriageTabOption.asignacionRapida,
    ParamedicoIncidentsRepository? repository,
    ImagePicker? picker,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       _picker = picker ?? ImagePicker(),
       activeTab = initialTab;

  final String? incidentId;
  bool get isStandalone => incidentId == null;
  final ParamedicoIncidentsRepository _repo;
  final ImagePicker _picker;

  StartTriageTabOption activeTab;
  TriageCategory? selectedCategory;
  final List<String> photos = [];
  String patientName = '';
  int protocolStep = 0;
  int patientNumber = 1;
  bool loadingPatientNumber = true;
  bool submitting = false;

  StartTriageBodyKind get bodyKind {
    if (selectedCategory != null) return StartTriageBodyKind.postClasificacion;
    if (activeTab == StartTriageTabOption.protocoloGuiado) {
      return StartTriageBodyKind.protocoloGuiado;
    }
    return StartTriageBodyKind.asignacionRapida;
  }

  String? get incidentBase =>
      incidentId != null ? '/paramedico/incident/$incidentId' : null;

  Future<void> loadPatientNumber() async {
    if (isStandalone) {
      patientNumber = 1;
      loadingPatientNumber = false;
      notifyListeners();
      return;
    }
    loadingPatientNumber = true;
    notifyListeners();
    try {
      final count = await _repo.countPatientsForIncident(incidentId!);
      patientNumber = count + 1;
    } catch (_) {
      patientNumber = 1;
    } finally {
      loadingPatientNumber = false;
      notifyListeners();
    }
  }

  void resetFlow() {
    selectedCategory = null;
    photos.clear();
    patientName = '';
    protocolStep = 0;
    notifyListeners();
  }

  void setActiveTab(StartTriageTabOption tab) {
    if (activeTab == tab) return;
    activeTab = tab;
    resetFlow();
  }

  void setSelectedCategory(TriageCategory? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setProtocolStep(int step) {
    protocolStep = step;
    notifyListeners();
  }

  void setPatientName(String name) {
    patientName = name;
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= photos.length) return;
    photos.removeAt(index);
    notifyListeners();
  }

  void leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final base = incidentBase;
    if (base != null) {
      context.go(base);
    } else {
      context.go('/paramedico/paciente');
    }
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

  void showImageSourceDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (ctx) {
        return SafeArea(
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
        );
      },
    );
  }

  Future<void> goRegister(BuildContext context) async {
    if (selectedCategory == null) return;
    if (isStandalone) {
      context.pop(
        StartTriageResult(
          triage: selectedCategory!,
          displayName: patientName.trim().isEmpty ? null : patientName.trim(),
        ),
      );
      return;
    }
    if (submitting) return;
    if (!SupabaseEnv.isConfigured) {
      showAppSnackBar(context, 'Supabase no configurado.', isError: true);
      return;
    }

    submitting = true;
    notifyListeners();

    try {
      final incident = await _repo.getIncident(incidentId!);
      if (incident == null) {
        throw Exception('Incidente no encontrado.');
      }
      final lat = incident.latitude;
      final lng = incident.longitude;
      if (lat == null || lng == null) {
        throw Exception('El incidente no tiene GPS capturado.');
      }

      final count = await _repo.countPatientsForIncident(incidentId!);
      final displayName = await PatientDisplayNameFormatter.resolveDisplayName(
        customName: patientName.trim().isEmpty ? null : patientName.trim(),
        patientNumber: count + 1,
        atLocal: DateTime.now(),
        lat: lat,
        lng: lng,
      );
      final demographics = <String, dynamic>{
        'photo_local_paths': List<String>.from(photos),
        'registered_from_start': true,
        'start_triage_mode': activeTab.name,
      };

      await _repo.registerPatientFull(
        incidentId: incidentId!,
        triageColor: selectedCategory!.sqlValue,
        displayName: displayName,
        demographics: demographics,
        locationLat: lat,
        locationLng: lng,
      );

      submitting = false;
      notifyListeners();
      if (!context.mounted) return;

      resetFlow();
      await loadPatientNumber();
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Paciente registrado.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}
