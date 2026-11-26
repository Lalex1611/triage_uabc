import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/domain/services/patient_demographics_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/patient_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/patient_details_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_map_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Contenedor del flujo de detalles del paciente para paramédicos
class PatientDetailsFlowPage extends StatefulWidget {
  const PatientDetailsFlowPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientDetailsFlowPage> createState() => _PatientDetailsFlowPageState();
}

class _PatientDetailsFlowPageState extends State<PatientDetailsFlowPage> {
  late final PatientDetailsController _controller;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _dayCtrl;
  late final TextEditingController _monthCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _descCtrl;
  bool _wasEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = PatientDetailsController(patientId: widget.patientId);
    _nameCtrl = TextEditingController();
    _dayCtrl = TextEditingController();
    _monthCtrl = TextEditingController();
    _yearCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _controller.addListener(_onController);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _nameCtrl.dispose();
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    _syncEditControllers();
    setState(() {});
  }

  void _syncEditControllers() {
    final c = _controller;
    if (!c.isEditing) {
      _wasEditing = false;
      return;
    }

    void setControllerText(TextEditingController ctrl, String value) {
      if (ctrl.text != value) {
        ctrl.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    }

    if (!_wasEditing) {
      _wasEditing = true;
      setControllerText(_nameCtrl, c.editName);
      setControllerText(_dayCtrl, c.editBirthDay?.toString() ?? '');
      setControllerText(_monthCtrl, c.editBirthMonth?.toString() ?? '');
      setControllerText(_yearCtrl, c.editBirthYear?.toString() ?? '');
      setControllerText(_contactCtrl, c.editContact ?? '');
      setControllerText(_descCtrl, c.editDescription);
      return;
    }

    if (_nameCtrl.text != c.editName) {
      setControllerText(_nameCtrl, c.editName);
    }
    if (_descCtrl.text != c.editDescription) {
      setControllerText(_descCtrl, c.editDescription);
    }
    if (int.tryParse(_dayCtrl.text.trim()) != c.editBirthDay) {
      setControllerText(_dayCtrl, c.editBirthDay?.toString() ?? '');
    }
    if (int.tryParse(_monthCtrl.text.trim()) != c.editBirthMonth) {
      setControllerText(_monthCtrl, c.editBirthMonth?.toString() ?? '');
    }
    if (int.tryParse(_yearCtrl.text.trim()) != c.editBirthYear) {
      setControllerText(_yearCtrl, c.editBirthYear?.toString() ?? '');
    }
    final normalizedContact = _contactCtrl.text.trim().isEmpty
        ? null
        : _contactCtrl.text.trim();
    if (normalizedContact != c.editContact) {
      setControllerText(_contactCtrl, c.editContact ?? '');
    }
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

    return _buildView(context, c);
  }

  // ---------------------------------------------------------------------------
  // Vista unificada (lectura y edición en línea con diseño B13)
  // ---------------------------------------------------------------------------

  static const int _photoColumns = 3;

  Widget _buildView(BuildContext context, PatientDetailsController c) {
    final d = c.detail!;
    final demo = d.demographics;
    final editing = c.isEditing;

    final baseLevel = TriageLevel.fromDb(d.triageColor) ?? TriageLevel.yellow;
    final level = editing
        ? (TriageLevel.fromDb(c.editTriage.sqlValue) ?? baseLevel)
        : baseLevel;
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

    final shownName = editing
        ? (c.editName.trim().isEmpty ? d.displayName : c.editName.trim())
        : d.displayName;

    final primaryLabel = switch (d.status) {
      'en_espera' => 'Enviar a hospital',
      'trasladando' => 'Reasignar hospital',
      _ => null,
    };

    return PopScope(
      canPop: !editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && editing && !c.savingEdit) {
          c.cancelEdit();
        }
      },
      child: Scaffold(
        backgroundColor: TriageColors.surface,
        resizeToAvoidBottomInset: editing,
        body: Column(
          children: [
            TriageDetailHeader(
              title: c.patientIdLabel(d),
              subtitle: incidentFolio == null
                  ? shownName
                  : '$shownName · $incidentFolio',
              onBack: () => c.onBack(context),
              onMore: editing ? null : () => unawaited(_openMenu(c, d)),
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
                            title: shownName,
                            onEdit: editing ? null : c.startEdit,
                          ),
                          if (editing) _buildIdentityAndTriageEditCard(c),
                          TriageSectionCard(
                            title: 'Estado actual',
                            trailing: lifecycle == null
                                ? null
                                : TriageStatusBadge.patient(lifecycle),
                            child: editing
                                ? Text(
                                    'Guarda o cancela la edición para cambiar el estado de traslado.',
                                    style: TriageTextStyles.bodySmall.copyWith(
                                      color: TriageColors.textSecondary,
                                    ),
                                  )
                                : statusOptions.isEmpty
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
                              onTap: () => editing
                                  ? c.showEditImageSourceDialog(context)
                                  : _addPhoto(c),
                            ),
                            child: GridView.count(
                              crossAxisCount: _photoColumns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: TriageSpacing.sm,
                              crossAxisSpacing: TriageSpacing.sm,
                              children: [
                                for (var i = 0; i < photos.length; i++)
                                  editing
                                      ? _EditablePhotoTile(
                                          path: photos[i],
                                          onRemove: () =>
                                              c.removeEditPhotoAt(i),
                                        )
                                      : TriagePhoto(
                                          image: FileImage(File(photos[i])),
                                        ),
                                if (!editing)
                                  for (final url in c.storedPhotoUrls.values)
                                    TriagePhoto(image: NetworkImage(url)),
                                if (editing ||
                                    (photos.isEmpty && c.storedPhotoUrls.isEmpty))
                                  TriagePhoto(
                                    onTap: () => editing
                                        ? c.showEditImageSourceDialog(context)
                                        : _addPhoto(c),
                                  ),
                              ],
                            ),
                          ),
                          TriageSectionCard(
                            title: 'Datos del paciente',
                            trailing: editing
                                ? null
                                : TriageSectionAction(
                                    label: 'Editar',
                                    icon: TriageIcons.pencil,
                                    onTap: c.startEdit,
                                  ),
                            child: editing
                                ? _buildPersonalDataEditForm(c)
                                : Column(
                                    children: _divided([
                                      TriageDataRow(
                                        label: 'Edad',
                                        value: age ?? '—',
                                      ),
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
                            trailing: editing
                                ? null
                                : TriageSectionAction(
                                    label: 'Editar',
                                    icon: TriageIcons.pencil,
                                    onTap: c.startEdit,
                                  ),
                            child: editing
                                ? _buildDescriptionEditForm(c)
                                : Text(
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
                    PatientMapWidget(
                      data: PatientMapData(
                        latitude: coords.$1,
                        longitude: coords.$2,
                        sectionTitle: editing
                            ? 'Ajuste la ubicación'
                            : 'Ubicación',
                        onOpenAppMapTap: () =>
                            unawaited(c.openMapFromSection(context)),
                        onOpenGoogleMapsTap: () =>
                            unawaited(c.openGoogleMapsForPatient(context)),
                        onTriangulateTap: editing
                            ? () => unawaited(
                                c.triangulatePatientLocation(context),
                              )
                            : null,
                        showTriangulationButton: editing,
                      ),
                    ),
                    const SizedBox(height: TriageSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: editing
            ? _EditActionBar(
                saving: c.savingEdit,
                onCancel: c.cancelEdit,
                onSave: () => unawaited(c.saveEdit(context)),
              )
            : _ActionBar(
                primaryLabel: primaryLabel,
                busy: c.wizardBusy,
                onPrimary: () => unawaited(
                  c.handleStatusPicked(context, PatientStatus.trasladando),
                ),
                onQr: () => unawaited(c.onGenerateQrTap(context)),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formularios en línea dentro de las tarjetas B13
  // ---------------------------------------------------------------------------

  Widget _buildIdentityAndTriageEditCard(PatientDetailsController c) {
    const categories = [
      (TriageCategory.rojo, 'Rojo'),
      (TriageCategory.amarillo, 'Amarillo'),
      (TriageCategory.verde, 'Verde'),
      (TriageCategory.negro, 'Negro'),
    ];

    return TriageSectionCard(
      title: 'Identificación y clasificación START',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TriageSpacing.md,
        children: [
          TextField(
            controller: _nameCtrl,
            onChanged: c.setEditName,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              label: 'Nombre del paciente',
              hint: 'Ej. Juan Pérez o Desconocido #1',
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: TriageSpacing.xs,
            children: [
              Text(
                'Prioridad START',
                style: TriageTextStyles.labelSmall.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
              Row(
                spacing: TriageSpacing.sm,
                children: [
                  for (final (category, label) in categories)
                    Expanded(
                      child: _TriageCategoryOption(
                        label: label,
                        color: category.color,
                        selected: c.editTriage == category,
                        onTap: () => c.setEditTriage(category),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataEditForm(PatientDetailsController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TriageSpacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: TriageSpacing.xs,
          children: [
            Text(
              'Fecha de nacimiento',
              style: TriageTextStyles.labelSmall.copyWith(
                color: TriageColors.textSecondary,
              ),
            ),
            Row(
              spacing: TriageSpacing.sm,
              children: [
                Expanded(
                  child: TextField(
                    controller: _dayCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (v) => c.setEditBirthDay(int.tryParse(v)),
                    decoration: _inputDecoration(label: 'Día', hint: 'DD'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _monthCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (v) => c.setEditBirthMonth(int.tryParse(v)),
                    decoration: _inputDecoration(label: 'Mes', hint: 'MM'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (v) => c.setEditBirthYear(int.tryParse(v)),
                    decoration: _inputDecoration(label: 'Año', hint: 'AAAA'),
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: TriageSpacing.xs,
          children: [
            Text(
              'Sexo',
              style: TriageTextStyles.labelSmall.copyWith(
                color: TriageColors.textSecondary,
              ),
            ),
            Wrap(
              spacing: TriageSpacing.sm,
              runSpacing: TriageSpacing.xs,
              children: [
                for (final g in PatientGender.values)
                  ChoiceChip(
                    label: Text(g.label),
                    selected: c.editGender == g,
                    selectedColor: TriageColors.paramedicAccent.withValues(
                      alpha: 0.14,
                    ),
                    labelStyle: TriageTextStyles.labelLarge.copyWith(
                      color: c.editGender == g
                          ? TriageColors.paramedicAccent
                          : TriageColors.textPrimary,
                    ),
                    side: BorderSide(
                      color: c.editGender == g
                          ? TriageColors.paramedicAccent
                          : TriageColors.borderMedium,
                    ),
                    onSelected: (selected) =>
                        c.setEditGender(selected ? g : null),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: TriageSpacing.xs,
          children: [
            Text(
              'Tipo de sangre',
              style: TriageTextStyles.labelSmall.copyWith(
                color: TriageColors.textSecondary,
              ),
            ),
            Wrap(
              spacing: TriageSpacing.sm,
              runSpacing: TriageSpacing.xs,
              children: [
                for (final b in PatientBloodType.values)
                  ChoiceChip(
                    label: Text(b.label),
                    selected: c.editBlood == b,
                    selectedColor: TriageColors.paramedicAccent.withValues(
                      alpha: 0.14,
                    ),
                    labelStyle: TriageTextStyles.labelLarge.copyWith(
                      color: c.editBlood == b
                          ? TriageColors.paramedicAccent
                          : TriageColors.textPrimary,
                    ),
                    side: BorderSide(
                      color: c.editBlood == b
                          ? TriageColors.paramedicAccent
                          : TriageColors.borderMedium,
                    ),
                    onSelected: (selected) =>
                        c.setEditBlood(selected ? b : null),
                  ),
              ],
            ),
          ],
        ),
        TextField(
          controller: _contactCtrl,
          keyboardType: TextInputType.phone,
          onChanged: (v) =>
              c.setEditContact(v.trim().isEmpty ? null : v.trim()),
          decoration: _inputDecoration(
            label: 'Contacto de emergencia',
            hint: 'Teléfono de familiar o responsable',
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionEditForm(PatientDetailsController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TriageSpacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: TriageSpacing.xs,
          children: [
            Text(
              'Lesiones observadas',
              style: TriageTextStyles.labelSmall.copyWith(
                color: TriageColors.textSecondary,
              ),
            ),
            Wrap(
              spacing: TriageSpacing.sm,
              runSpacing: TriageSpacing.xs,
              children: [
                for (final injury in PatientInjuryType.values)
                  FilterChip(
                    label: Text(injury.label),
                    selected: c.editInjuries.contains(injury),
                    selectedColor: TriageColors.paramedicAccent.withValues(
                      alpha: 0.14,
                    ),
                    checkmarkColor: TriageColors.paramedicAccent,
                    labelStyle: TriageTextStyles.bodySmall.copyWith(
                      color: c.editInjuries.contains(injury)
                          ? TriageColors.paramedicAccent
                          : TriageColors.textPrimary,
                      fontWeight: c.editInjuries.contains(injury)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: c.editInjuries.contains(injury)
                          ? TriageColors.paramedicAccent
                          : TriageColors.borderMedium,
                    ),
                    onSelected: (_) => c.toggleEditInjury(injury),
                  ),
              ],
            ),
          ],
        ),
        TextField(
          controller: _descCtrl,
          minLines: 3,
          maxLines: 5,
          onChanged: c.setEditDescription,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            label: 'Observaciones clínicas',
            hint: 'Describe signos vitales, lesiones o evolución del paciente',
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    final radius = BorderRadius.circular(TriageRadii.md);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: TriageColors.sunken,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TriageSpacing.md,
        vertical: TriageSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: TriageColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: TriageColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(
          color: TriageColors.paramedicAccent,
          width: 1.5,
        ),
      ),
    );
  }

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

class _TriageCategoryOption extends StatelessWidget {
  const _TriageCategoryOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TriageRadii.md);
    return Material(
      color: selected ? color.withValues(alpha: 0.16) : TriageColors.sunken,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: TriageSpacing.sm,
            horizontal: TriageSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? color : TriageColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TriageTextStyles.labelSmall.copyWith(
                  color: TriageColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditablePhotoTile extends StatelessWidget {
  const _EditablePhotoTile({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imageProvider = FileImage(File(path));
    return Stack(
      fit: StackFit.expand,
      children: [
        TriagePhoto(
          image: imageProvider,
          onTap: () => showTriagePhotoViewer(context, photos: [imageProvider]),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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

/// Barra inferior en modo edición: Cancelar / Guardar dentro del mismo diseño
class _EditActionBar extends StatelessWidget {
  const _EditActionBar({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              spacing: TriageSpacing.md,
              children: [
                Expanded(
                  child: TriageButton(
                    label: 'Cancelar',
                    variant: TriageButtonVariant.secondary,
                    onPressed: saving ? null : onCancel,
                  ),
                ),
                Expanded(
                  child: TriageButton(
                    label: 'Guardar',
                    isLoading: saving,
                    onPressed: saving ? null : onSave,
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
