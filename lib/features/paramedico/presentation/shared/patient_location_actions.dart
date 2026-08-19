import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_location_map_dialog_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/patient_location_picker_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Funciones compartidas para interacción con mapas y ubicación GPS del paciente
class PatientLocationActions {
  PatientLocationActions._();

  static Future<LatLng?> pickInAppMap(
    BuildContext context, {
    required double lat,
    required double lng,
    String title = 'Ubicación del paciente',
  }) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PatientLocationPickerPage(
          initialLat: lat,
          initialLng: lng,
          title: title,
        ),
      ),
    );
  }

  static Future<void> openGoogleMaps(
    BuildContext context, {
    required double lat,
    required double lng,
  }) async {
    final u = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final can = await canLaunchUrl(u);
    if (!context.mounted) return;
    if (can) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    } else {
      showAppSnackBar(context, 'No se pudo abrir Google Maps.', isError: true);
    }
  }

  static Future<LatLng?> captureCurrentPosition(BuildContext context) async {
    final pos = await IncidentLocationService.getCurrentPosition();
    if (!context.mounted) return null;
    if (pos == null) {
      showAppSnackBar(
        context,
        IncidentLocationService.errorMessageForNullResult() ?? 'Sin ubicación GPS.',
        isError: true,
      );
      return null;
    }
    return LatLng(pos.lat, pos.lng);
  }

  static Future<void> showPreview(
    BuildContext context, {
    required double lat,
    required double lng,
    String title = 'Ubicación del paciente',
  }) {
    return IncidentLocationMapDialog.showPreview(
      context,
      lat: lat,
      lng: lng,
      title: title,
    );
  }
}
