import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_record_app_bar_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_actions_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_photo_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_triage_classification_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/patient_registration_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/patient_registration_page.dart';

/// Contenedor del flujo de registro completo de pacientes
class PatientRegistrationFlowPage extends StatefulWidget {
  const PatientRegistrationFlowPage({
    super.key,
    this.incidentId,
    this.seedLatitude,
    this.seedLongitude,
  });

  final String? incidentId;
  final double? seedLatitude;
  final double? seedLongitude;

  @override
  State<PatientRegistrationFlowPage> createState() =>
      _PatientRegistrationFlowPageState();
}

class _PatientRegistrationFlowPageState
    extends State<PatientRegistrationFlowPage> {
  late final PatientRegistrationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PatientRegistrationController(
      incidentId: widget.incidentId,
      seedLatitude: widget.seedLatitude,
      seedLongitude: widget.seedLongitude,
    );
    _controller.addListener(_onController);
    _controller.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.applyQueryParamsIfChanged(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Theme(
      data: appTheme,
      child: PatientRegistrationPage(
        appBarData: PatientRecordAppBarData(
          triageCategory: c.triageCategory,
          backLabel: 'Regresar a Home',
          onBackTap: () => c.goBack(context),
        ),
        actionsData: PatientActionsData(
          onCancelTap: () => c.goBack(context),
          onConfirmTap: c.submitting ? () {} : () => c.submit(context),
        ),
        headerData: PatientHeaderData(
          patientId: 'Nuevo',
          gpsCoordinates: c.gpsCoordinatesLabel,
          isGpsCaptured: !c.patientCoordsLoading,
          triageCategory: c.triageCategory,
          patientName: c.displayName.isEmpty ? null : c.displayName,
          onShowMapTap: () => c.openMapPreview(context),
          onEditLocationTap: () => c.openPatientLocationPicker(context),
          onGenerateQrTap: () => c.showQrUnavailableMessage(context),
          onNameChanged: c.setDisplayName,
          isQrEnabled: false,
          qrButtonLabel: 'QR disponible\nal registrar',
        ),
        photoData: PatientPhotoData(
          photos: c.photos,
          onAddPhotoTap: () => c.showImageSourceDialog(context),
          onRemovePhotoTap: c.removePhotoAt,
        ),
        triageData: PatientTriageClassificationData(
          selectedCategory: c.triageCategory,
          onCategorySelected: c.setTriageCategory,
          onStartTriageTap: () => c.openGuidedProtocol(context),
        ),
        mapSectionKey: c.mapSectionKey,
        mapData: PatientMapData(
          latitude: c.patientLat,
          longitude: c.patientLng,
          sectionTitle: 'Ajuste la ubicación',
          onOpenAppMapTap: () => c.openPatientLocationPicker(context),
          onOpenGoogleMapsTap: () => c.openGoogleMaps(context),
          onTriangulateTap: () => c.triangulateLocation(context),
        ),
        personalData: PatientPersonalData(
          gender: c.gender,
          bloodType: c.bloodType,
          birthDay: c.birthDay,
          birthMonth: c.birthMonth,
          birthYear: c.birthYear,
          contactNumber: c.contactNumber.isEmpty ? null : c.contactNumber,
          onDayChanged: c.setBirthDay,
          onMonthChanged: c.setBirthMonth,
          onYearChanged: c.setBirthYear,
          onGenderChanged: c.setGender,
          onBloodTypeChanged: c.setBloodType,
          onContactNumberChanged: c.setContactNumber,
        ),
        descriptionData: PatientDescriptionData(
          selectedInjuries: c.selectedInjuries,
          descriptionText: c.description,
          onInjuryToggled: c.toggleInjury,
          onDescriptionChanged: c.setDescription,
        ),
      ),
    );
  }
}
