import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_map_widget.dart';
import 'package:sistema_triage/shared/domain/patient_lifecycle_status.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';
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

    // Lectura: diseño nuevo (B13). Edición: pantalla anterior, sin cambios
    if (!c.isEditing) return _buildView(context, c);

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

  // ---------------------------------------------------------------------------
  // Vista de lectura (B13)
  // ---------------------------------------------------------------------------

  static const int _photoColumns = 3;

  Widget _buildView(BuildContext context, PatientDetailsController c) {
    final d = c.detail!;
    final demo = d.demographics;
    final level = TriageLevel.fromDb(d.triageColor) ?? TriageLevel.yellow;
    final lifecycle = PatientLifecycleStatus.fromDb(d.status);
    final statusOptions = c.wizardBusy
        ? const <(String, PatientStatus)>[]
        : _statusOptions(c.statusMenuEntries(d.status));

    final gender = PatientDemographicsMapper.genderFromDemo(
      demo['gender'] as String?,
    );
    final blood = PatientDemographicsMapper.bloodFromDemo(
      demo['blood_type'] as String?,
    );
    final age = _ageLabel(
      day: (demo['birth_day'] as num?)?.toInt(),
      month: (demo['birth_month'] as num?)?.toInt(),
      year: (demo['birth_year'] as num?)?.toInt(),
    );
    final contact = (demo['emergency_contact'] as String?)?.trim() ?? '';
    final description = (demo['description'] as String? ?? '').trim();
    final photos = c.photoPathsForUi(d);
    final coords = c.patientMapCoords(d);
    final folio = d.regulationFolio?.trim() ?? '';
    final hospitalName = c.assignedHospital?.name ?? '';
    final incidentFolio = _incidentFolio(c);

    final primaryLabel = switch (d.status) {
      'en_espera' => 'Enviar a hospital',
      'trasladando' => 'Reasignar hospital',
      _ => null,
    };

    return Scaffold(
      // Figma usa un fondo gris claro; cámbialo por el token de fondo cuando lo confirmes
      backgroundColor: TriageColors.surface,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          TriageDetailHeader(
            title: c.patientIdLabel(d),
            subtitle: incidentFolio == null
                ? d.displayName
                : '${d.displayName} · $incidentFolio',
            onBack: () => c.onBack(context),
            onMore: () => unawaited(_openMenu(c, d)),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(TriageSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: TriageSpacing.md,
                      children: [
                        TriagePatientBanner(
                          level: level,
                          tag: '${level.label} · ${level.startName}'
                              .toUpperCase(),
                          title: d.displayName,
                          onEdit: c.startEdit,
                        ),
                        TriageSectionCard(
                          title: 'Estado actual',
                          trailing: lifecycle == null
                              ? null
                              : TriageStatusBadge.patient(lifecycle),
                          child: statusOptions.isEmpty
                              ? Text(
                            c.wizardBusy
                                ? 'Actualizando…'
                                : 'Sin cambios disponibles en este estado.',
                            style: TriageTextStyles.bodySmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          )
                              : _StatusPicker(
                            onTap: () => unawaited(
                              _openStatusPicker(c, statusOptions),
                            ),
                          ),
                        ),
                        TriageSectionCard(
                          title: 'Fotografías',
                          trailing: TriageSectionAction(
                            label: 'Añadir',
                            onTap: () => _addPhoto(c),
                          ),
                          child: GridView.count(
                            crossAxisCount: _photoColumns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: TriageSpacing.sm,
                            crossAxisSpacing: TriageSpacing.sm,
                            children: [
                              for (final path in photos)
                                TriagePhoto(image: FileImage(File(path))),
                              if (photos.isEmpty)
                                TriagePhoto(onTap: () => _addPhoto(c)),
                            ],
                          ),
                        ),
                        TriageSectionCard(
                          title: 'Datos del paciente',
                          trailing: TriageSectionAction(
                            label: 'Editar',
                            icon: TriageIcons.pencil,
                            onTap: c.startEdit,
                          ),
                          child: Column(
                            children: _divided([
                              TriageDataRow(label: 'Edad', value: age ?? '—'),
                              TriageDataRow(
                                label: 'Sexo',
                                value: gender?.label ?? '—',
                              ),
                              TriageDataRow(
                                label: 'Tipo de sangre',
                                value: blood?.label ?? '—',
                              ),
                              if (contact.isNotEmpty)
                                TriageDataRow(
                                  label: 'Contacto de emergencia',
                                  value: contact,
                                ),
                            ]),
                          ),
                        ),
                        TriageSectionCard(
                          title: 'Estado y lesiones',
                          trailing: TriageSectionAction(
                            label: 'Editar',
                            icon: TriageIcons.pencil,
                            onTap: c.startEdit,
                          ),
                          child: Text(
                            description.isEmpty
                                ? 'Sin descripción.'
                                : description,
                            style: TriageTextStyles.bodyMedium.copyWith(
                              color: description.isEmpty
                                  ? TriageColors.textSecondary
                                  : TriageColors.textPrimary,
                            ),
                          ),
                        ),
                        if (folio.isNotEmpty || hospitalName.isNotEmpty)
                          TriageSectionCard(
                            title: 'Traslado',
                            child: Column(
                              children: _divided([
                                if (hospitalName.isNotEmpty)
                                  TriageDataRow(
                                    label: 'Hospital',
                                    value: hospitalName,
                                  ),
                                if (folio.isNotEmpty)
                                  TriageDataRow(
                                    label: 'Folio de regulación',
                                    value: folio,
                                  ),
                              ]),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Mapa: se conserva el widget anterior hasta migrarlo con
                  // TriageMapTiles y TriagePatientMarker
                  PatientMapWidget(
                    data: PatientMapData(
                      latitude: coords.$1,
                      longitude: coords.$2,
                      sectionTitle: 'Ubicación',
                      onOpenAppMapTap: () =>
                          unawaited(c.openMapFromSection(context)),
                      onOpenGoogleMapsTap: () =>
                          unawaited(c.openGoogleMapsForPatient(context)),
                      onTriangulateTap: null,
                      showTriangulationButton: false,
                    ),
                  ),
                  const SizedBox(height: TriageSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        primaryLabel: primaryLabel,
        busy: c.wizardBusy,
        onPrimary: () => unawaited(
          c.handleStatusPicked(context, PatientStatus.trasladando),
        ),
        onQr: () => unawaited(c.onGenerateQrTap(context)),
      ),
    );
  }

  // "Añadir" foto y "Editar" entran al modo de edición anterior
  void _addPhoto(PatientDetailsController c) {
    c.startEdit();
    c.showEditImageSourceDialog(context);
  }

  Future<void> _openMenu(
      PatientDetailsController c,
      ParamedicoPatientDetail d,
      ) async {
    final action = await showTriageSheet<_PatientMenuAction>(
      context,
      title: 'Opciones del paciente',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.showExportRoute(d))
            _SheetTile(
              icon: TriageIcons.navigation,
              label: 'Exportar ruta al hospital',
              onTap: () =>
                  Navigator.pop(sheetContext, _PatientMenuAction.exportRoute),
            ),
          _SheetTile(
            icon: TriageIcons.check,
            label: 'Cerrar paciente',
            onTap: () =>
                Navigator.pop(sheetContext, _PatientMenuAction.closePatient),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _PatientMenuAction.exportRoute:
        unawaited(c.exportRoute(context));
      case _PatientMenuAction.closePatient:
        unawaited(c.confirmClosePatient(context));
    }
  }

  Future<void> _openStatusPicker(
      PatientDetailsController c,
      List<(String, PatientStatus)> options,
      ) async {
    final chosen = await showTriageSheet<PatientStatus>(
      context,
      title: 'Cambiar estado',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, status) in options)
            _SheetTile(
              label: label,
              onTap: () => Navigator.pop(sheetContext, status),
            ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    c.onStatusMenuSelection(context, chosen);
  }

  /// Opciones de estado a partir del menú que ya define el controlador
  static List<(String, PatientStatus)> _statusOptions(
      List<PopupMenuEntry<PatientStatus>>? entries,
      ) {
    if (entries == null) return const [];
    return [
      for (final e in entries)
        if (e is PopupMenuItem<PatientStatus>)
          if (e.value case final value?)
            if (e.child case Text(data: final label?)) (label, value),
    ];
  }

  /// Folio del incidente, calculado igual que en la lista de incidentes
  String? _incidentFolio(PatientDetailsController c) {
    final inc = c.incident;
    if (inc == null) return null;
    return IncidentForCardsMapper.fromSummary(
      summary: inc,
      counts: IncidentForCardsMapper.countsFor(inc.id, const {}),
      currentUserId: '',
    ).id;
  }

  static String? _ageLabel({int? day, int? month, int? year}) {
    if (year == null) return null;
    final now = DateTime.now();
    var age = now.year - year;
    if (month != null &&
        (now.month < month ||
            (now.month == month && day != null && now.day < day))) {
      age--;
    }
    if (age < 0) return null;
    return age == 1 ? '1 año' : '$age años';
  }

  static List<Widget> _divided(List<Widget> rows) => [
    for (var i = 0; i < rows.length; i++) ...[
      if (i > 0)
        const Divider(
          height: TriageSizes.hairline,
          thickness: TriageSizes.hairline,
          color: TriageColors.borderSubtle,
        ),
      rows[i],
    ],
  ];
}

enum _PatientMenuAction { exportRoute, closePatient }

/// Selector "Cambiar estado" de B13: barra gris con chevron
class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TriageRadii.md);
    return Semantics(
      button: true,
      child: Material(
        color: TriageColors.sunken,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TriageSizes.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TriageSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cambiar estado',
                      style: TriageTextStyles.labelLarge.copyWith(
                        color: TriageColors.textPrimary,
                      ),
                    ),
                  ),
                  const TriageIcon(
                    TriageIcons.chevronDown,
                    size: TriageSizes.icon,
                    color: TriageColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de opción de las hojas del menú y del selector de estado
class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return ListTile(
      onTap: onTap,
      leading: icon == null
          ? null
          : TriageIcon(
        icon,
        size: TriageSizes.icon,
        color: TriageColors.textSecondary,
      ),
      title: Text(
        label,
        style: TriageTextStyles.bodyMedium.copyWith(
          color: TriageColors.textPrimary,
        ),
      ),
    );
  }
}

/// Barra inferior de B13: código de consulta y acción principal del traslado
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.primaryLabel,
    required this.busy,
    required this.onPrimary,
    required this.onQr,
  });

  final String? primaryLabel;
  final bool busy;
  final VoidCallback onPrimary;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    final label = primaryLabel;
    return Material(
      color: TriageColors.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: TriageColors.borderSubtle,
              width: TriageSizes.hairline,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(TriageSpacing.lg),
            child: label == null
                ? TriageButton(
              label: 'Código de consulta',
              variant: TriageButtonVariant.secondary,
              onPressed: onQr,
            )
                : Row(
              spacing: TriageSpacing.md,
              children: [
                TriageIconButton(
                  icon: TriageIcons.qr,
                  tooltip: 'Código de consulta',
                  onPressed: onQr,
                  size: TriageIconButtonSize.large,
                ),
                Expanded(
                  child: TriageButton(
                    label: label,
                    isLoading: busy,
                    onPressed: onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}