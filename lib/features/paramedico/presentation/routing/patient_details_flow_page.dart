import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_photo_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_status_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_triage_classification_data.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_demographics_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/patient_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/patient_details_page.dart';

/// Contenedor del flujo de detalles del paciente para paramédicos
class PatientDetailsFlowPage extends StatefulWidget {
  const PatientDetailsFlowPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientDetailsFlowPage> createState() => _PatientDetailsFlowPageState();
}

class _PatientDetailsFlowPageState extends State<PatientDetailsFlowPage> {
  late final PatientDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PatientDetailsController(patientId: widget.patientId);
    _controller.addListener(_onController);
    unawaited(_controller.load());
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
    final mode = c.shellMode;

    if (mode != PatientDetailsShellMode.ready) {
      return PatientDetailsPage(
        shellMode: mode,
        errorMessage: c.error,
        bodyChildren: const [],
      );
    }

    final d = c.detail!;
    final demo = d.demographics;
    final tri = c.isEditing
        ? c.editTriage
        : ParamedicoCatalogMappers.triageFromDb(d.triageColor);
    final st = ParamedicoCatalogMappers.statusFromDb(d.status);
    final injurySet = c.isEditing
        ? c.editInjuries
        : PatientDemographicsMapper.injuriesFromDemo(demo);
    final desc = c.isEditing
        ? c.editDescription
        : (demo['description'] as String? ?? '');
    final gender = c.isEditing
        ? c.editGender
        : PatientDemographicsMapper.genderFromDemo(demo['gender'] as String?);
    final blood = c.isEditing
        ? c.editBlood
        : PatientDemographicsMapper.bloodFromDemo(
            demo['blood_type'] as String?,
          );
    final photoPaths = c.photoPathsForUi(d);
    final mapCoords = c.patientMapCoords(d);
    final birthDay = c.isEditing
        ? c.editBirthDay
        : (demo['birth_day'] as num?)?.toInt();
    final birthMonth = c.isEditing
        ? c.editBirthMonth
        : (demo['birth_month'] as num?)?.toInt();
    final birthYear = c.isEditing
        ? c.editBirthYear
        : (demo['birth_year'] as num?)?.toInt();
    final contact = c.isEditing
        ? c.editContact
        : (demo['emergency_contact'] as String?);
    final displayName = c.isEditing ? c.editName : d.displayName;
    final statusMenu = c.statusMenuEntries(d.status);
    final canOpenStatusMenu =
        !c.isEditing && statusMenu != null && !c.wizardBusy;
    final formReadOnly = !c.isEditing;

    final extra = <Widget>[
      if (d.regulationFolio != null && d.regulationFolio!.trim().isNotEmpty)
        PatientDetailsPage.infoSection(
          'Folio de regulación',
          d.regulationFolio!.trim(),
        ),
      if (c.assignedHospital?.name != null &&
          c.assignedHospital!.name.isNotEmpty)
        PatientDetailsPage.infoSection(
          'Hospital de traslado',
          c.assignedHospital!.name,
        ),
    ];

    Widget? trailing;
    if (c.showExportRoute(d)) {
      trailing = PatientDetailsPage.exportRouteButton(
        onPressed: () => unawaited(c.exportRoute(context)),
      );
    }

    return PatientDetailsPage(
      shellMode: mode,
      appBar: PatientDetailsPage.readyAppBar(
        triageCategory: tri,
        onBackTap: () => c.onBack(context),
        onClosePatientTap: () => unawaited(c.confirmClosePatient(context)),
      ),
      stickyActionBar: c.isEditing
          ? PatientDetailsPage.readyBottomBar(
              savingEdit: c.savingEdit,
              onCancel: c.cancelEdit,
              onConfirm: () => unawaited(c.saveEdit(context)),
            )
          : null,
      bottomPadding: c.isEditing ? 120 : (trailing == null ? 24 : 0),
      bodyChildren: PatientDetailsPage.readyBody(
        headerData: DetailsHeaderData(
          patientId: c.patientIdLabel(d),
          patientName: displayName,
          gpsCoordinates: c.gpsLabel(d),
          triageCategory: tri,
          isEditing: c.isEditing,
          showEditButton: !c.isEditing,
          onStartEditTap: c.startEdit,
          onNameChanged: c.setEditName,
          onGenerateQrTap: () => unawaited(c.onGenerateQrTap(context)),
          onShowMapTap: () {
            if (c.isEditing) {
              unawaited(c.openMapPreview(context));
            } else {
              c.openInteractiveMap(context);
            }
          },
          onEditMapTap: () => unawaited(c.openEditLocation(context)),
        ),
        statusData: DetailsStatusData(
          creatorName: c.creatorName ?? '—',
          timeElapsed: IncidentPresentationFormatters.relativeCreated(
            d.createdAt,
          ),
          currentStatus: st,
          canEdit: canOpenStatusMenu,
          statusMenuEntries: statusMenu,
          onStatusChanged: (s) => c.onStatusMenuSelection(context, s),
        ),
        photoData: DetailsPhotoData(
          photos: photoPaths,
          isReadOnly: formReadOnly,
          onAddPhotoTap: () => c.showEditImageSourceDialog(context),
          onRemovePhotoTap: c.removeEditPhotoAt,
        ),
        triageData: PatientTriageClassificationData(
          selectedCategory: tri,
          onCategorySelected: formReadOnly ? (_) {} : c.setEditTriage,
          onStartTriageTap: null,
          sectionTitle: 'Seleccione la clasificación START',
          dimUnselectedColors: formReadOnly,
        ),
        mapData: PatientMapData(
          latitude: mapCoords.$1,
          longitude: mapCoords.$2,
          sectionTitle: 'Ajuste la ubicación',
          onOpenAppMapTap: () => unawaited(c.openMapFromSection(context)),
          onOpenGoogleMapsTap: () =>
              unawaited(c.openGoogleMapsForPatient(context)),
          onTriangulateTap: formReadOnly
              ? null
              : () => unawaited(c.triangulatePatientLocation(context)),
          showTriangulationButton: !formReadOnly,
        ),
        personalData: PatientPersonalData(
          birthDay: birthDay,
          birthMonth: birthMonth,
          birthYear: birthYear,
          gender: gender,
          bloodType: blood,
          contactNumber: contact,
          isReadOnly: formReadOnly,
          onDayChanged: (v) => c.setEditBirthDay(int.tryParse(v)),
          onMonthChanged: (v) => c.setEditBirthMonth(int.tryParse(v)),
          onYearChanged: (v) => c.setEditBirthYear(int.tryParse(v)),
          onGenderChanged: c.setEditGender,
          onBloodTypeChanged: c.setEditBlood,
          onContactNumberChanged: c.setEditContact,
        ),
        descriptionData: PatientDescriptionData(
          selectedInjuries: injurySet,
          descriptionText: desc,
          isReadOnly: formReadOnly,
          onInjuryToggled: formReadOnly ? (_) {} : c.toggleEditInjury,
          onDescriptionChanged: c.setEditDescription,
        ),
        extraSections: extra,
        trailing: trailing,
      ),
    );
  }
}
