import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Callback asíncrono para el envío de datos de traslado
typedef OnSubmitTransfer = Future<void> Function(Map<String, dynamic> data);

/// Función global para desplegar la hoja modal de traslado
Future<String?> showAssignTransferSheet(
  BuildContext context, {
  String patientName = 'Paciente',
  String patientFolio = '',
  TriageLevel triageLevel = TriageLevel.green,
  String conditionSummary = '',
  List<HospitalRow> hospitals = const <HospitalRow>[],
  List<String> ambulanceUnits = const <String>[],
  List<String> insuranceOptions = const <String>[
    'IMSS',
    'ISSSTE',
    'IMSS-Bienestar',
    'Particular',
  ],
  VoidCallback? onCancel,
  OnSubmitTransfer? onSubmit,
}) {
  return showTriageSheet(
    context,
    dismissible: false,
    showClose: false,
    builder: (BuildContext sheetContext) => AssignTransferSheet(
      patientName: patientName,
      patientFolio: patientFolio,
      triageLevel: triageLevel,
      conditionSummary: conditionSummary,
      hospitals: hospitals,
      ambulanceUnits: ambulanceUnits,
      insuranceOptions: insuranceOptions,
      onCancel: onCancel,
      onSubmit: onSubmit,
    ),
  );
}

/// Widget modal de 4 pasos adaptado a la lista de [HospitalRow]
class AssignTransferSheet extends StatefulWidget {
  final String patientName;
  final String patientFolio;
  final TriageLevel triageLevel;
  final String conditionSummary;

  final List<HospitalRow> hospitals;
  final List<String> ambulanceUnits;
  final List<String> insuranceOptions;

  final VoidCallback? onCancel;
  final OnSubmitTransfer? onSubmit;

  const AssignTransferSheet({
    super.key,
    this.patientName = 'Paciente',
    this.patientFolio = '',
    this.triageLevel = TriageLevel.green,
    this.conditionSummary = '',
    this.hospitals = const <HospitalRow>[],
    this.ambulanceUnits = const <String>[],
    this.insuranceOptions = const <String>[
      'IMSS',
      'ISSSTE',
      'IMSS-Bienestar',
      'Particular',
    ],
    this.onCancel,
    this.onSubmit,
  });

  @override
  State<AssignTransferSheet> createState() => _AssignTransferSheetState();
}

class _AssignTransferSheetState extends State<AssignTransferSheet> {
  int _currentStep = 1;
  bool _submitting = false;
  String? _submitError;

  // Paso 1: Seguro médico
  int _insuranceOptionIndex = 0; // 0: Sí, 1: No, 2: No sé
  String? _selectedInstitution;

  // Paso 2: Selección de hospital
  String _searchQuery = '';
  HospitalRow? _selectedHospital;

  // Paso 3: Unidad y Folio
  String? _selectedUnit;
  final TextEditingController _folioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final List<HospitalRow> hList = widget.hospitals;
    final List<String> uList = widget.ambulanceUnits;
    final List<String> iList = widget.insuranceOptions;

    if (hList.isNotEmpty) {
      _selectedHospital = hList.first;
    }
    if (uList.isNotEmpty) {
      _selectedUnit = uList.first;
    }
    if (iList.isNotEmpty) {
      _selectedInstitution = iList.first;
    }
  }

  @override
  void dispose() {
    _folioController.dispose();
    super.dispose();
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 1:
        return 'Paso 1 de 3 · seguro médico';
      case 2:
        return 'Paso 2 de 3 · hospital destino';
      case 3:
        return 'Paso 3 de 3 · regulación y unidad';
      case 4:
        return '${widget.patientFolio} · ${widget.patientName}';
      default:
        return '';
    }
  }

  String get _insuranceLabel {
    switch (_insuranceOptionIndex) {
      case 0:
        return _selectedInstitution ?? 'Sí';
      case 1:
        return 'No tiene seguro';
      default:
        return 'No lo sé';
    }
  }

  Future<void> _finishTransfer() async {
    if (_submitting) return;
    final HospitalRow? picked = _selectedHospital;
    final Map<String, dynamic> payload = <String, dynamic>{
      'picked_hospital': picked,
      'hospital_id': picked?.id,
      'hospital_name': picked?.name ?? '',
      'unit': _selectedUnit,
      'insurance': _insuranceLabel,
      'regulation_folio': _folioController.text.trim().isEmpty
          ? null
          : _folioController.text.trim(),
    };

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _currentStep = 4;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = _currentStep == 4;

    return TriageSheet(
      title: isConfirmed ? 'Traslado confirmado' : 'Asignar traslado',
      subtitle: _stepSubtitle,
      steps: isConfirmed ? null : TriageSteps(current: _currentStep, total: 3),
      onClose: () {
        if (_submitting) return;
        Navigator.pop(context);
        widget.onCancel?.call();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentStepView(),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Insurance();
      case 2:
        return _buildStep2Hospital();
      case 3:
        return _buildStep3Confirmation();
      case 4:
        return _buildStep4Confirmed();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- PASO 1: SEGURO MÉDICO ---
  Widget _buildStep1Insurance() {
    final List<String> optionsList = widget.insuranceOptions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(TriageSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TriagePatientStrip(
                level: widget.triageLevel,
                name: widget.patientFolio.isEmpty
                    ? widget.patientName
                    : '${widget.patientName} · ${widget.patientFolio}',
                detail: widget.conditionSummary,
              ),
              const SizedBox(height: TriageSpacing.xl),
              Text(
                '¿El paciente cuenta con seguro médico?',
                style: TriageTextStyles.titleMedium.copyWith(
                  color: TriageColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TriageSpacing.xs),
              Text(
                'Con esto el hospital sabe por dónde ingresarlo. Si no lo sabes, elige "No lo sé".',
                style: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
              const SizedBox(height: TriageSpacing.lg),
              TriageRadioOption(
                title: 'Sí, tiene seguro',
                detail: 'Elige la institución en el siguiente campo',
                selected: _insuranceOptionIndex == 0,
                tone: TriageTone.success,
                onTap: () => setState(() => _insuranceOptionIndex = 0),
              ),
              const SizedBox(height: TriageSpacing.md),
              TriageRadioOption(
                title: 'No tiene seguro',
                detail: 'Ingresa como paciente particular',
                selected: _insuranceOptionIndex == 1,
                onTap: () => setState(() => _insuranceOptionIndex = 1),
              ),
              const SizedBox(height: TriageSpacing.md),
              TriageRadioOption(
                title: 'No lo sé',
                detail: 'El hospital lo verificará al recibirlo',
                selected: _insuranceOptionIndex == 2,
                onTap: () => setState(() => _insuranceOptionIndex = 2),
              ),
              if (_insuranceOptionIndex == 0 && optionsList.isNotEmpty) ...[
                const SizedBox(height: TriageSpacing.xl),
                TriageSelectField<String>(
                  label: 'Institución',
                  value: _selectedInstitution,
                  options: optionsList,
                  optionLabel: (String val) => val,
                  onChanged: (String? val) =>
                      setState(() => _selectedInstitution = val),
                ),
              ],
            ],
          ),
        ),
        TriageActionBar(
          primary: TriageButton(
            label: 'Continuar',
            onPressed: () => setState(() => _currentStep = 2),
          ),
        ),
      ],
    );
  }

  // --- PASO 2: SELECCIÓN DE HOSPITAL (HospitalRow) ---
  Widget _buildStep2Hospital() {
    final List<HospitalRow> hospitalList = widget.hospitals;
    final List<HospitalRow> filtered = hospitalList.where((HospitalRow h) {
      final String q = _searchQuery.toLowerCase();
      final String name = h.name.toLowerCase();
      final String address = (h.address ?? '').toLowerCase();
      return name.contains(q) || address.contains(q);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(TriageSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TriagePatientStrip(
                level: widget.triageLevel,
                name: widget.patientFolio.isEmpty
                    ? widget.patientName
                    : '${widget.patientName} · ${widget.patientFolio}',
                detail: widget.conditionSummary,
              ),
              const SizedBox(height: TriageSpacing.lg),
              TriageSearchBar(
                hint: 'Buscar hospital',
                onChanged: (String val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: TriageSpacing.lg),
              const TriageAlert(
                tone: TriageTone.info,
                title: 'Ordenados por cercanía',
                message:
                    'Solo aparecen hospitales activos que pueden recibir en este momento.',
              ),
              const SizedBox(height: TriageSpacing.lg),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: TriageSpacing.xl,
                  ),
                  child: Center(
                    child: Text(
                      'No hay hospitales disponibles',
                      style: TriageTextStyles.bodyMedium.copyWith(
                        color: TriageColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...filtered.map((HospitalRow h) {
                  final bool isSelected = _selectedHospital?.id == h.id;
                  final bool hasCoords =
                      h.latitude != null && h.longitude != null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: TriageSpacing.md),
                    child: TriageTapCard(
                      selected: isSelected,
                      borderColor: isSelected
                          ? TriageColors.hospitalAccent
                          : TriageColors.borderMedium,
                      onTap: () => setState(() => _selectedHospital = h),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(TriageSpacing.sm),
                            decoration: BoxDecoration(
                              color: TriageColors.infoBackground,
                              borderRadius: BorderRadius.circular(
                                TriageRadii.md,
                              ),
                            ),
                            child: const TriageIcon(
                              TriageIcons.hospital,
                              color: TriageColors.hospitalAccent,
                              size: TriageSizes.icon,
                            ),
                          ),
                          const SizedBox(width: TriageSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.name,
                                  style: TriageTextStyles.labelLarge,
                                ),
                                Text(
                                  h.address ??
                                      (hasCoords
                                          ? 'Sin dirección especificada'
                                          : 'Sin coordenadas en base de datos'),
                                  style: TriageTextStyles.bodySmall.copyWith(
                                    color: hasCoords
                                        ? TriageColors.textSecondary
                                        : TriageColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: TriageSpacing.xs),
                                Row(
                                  children: [
                                    Text(
                                      hasCoords
                                          ? 'Disponible'
                                          : 'Sin ubicación',
                                      style: TriageTextStyles.labelSmall
                                          .copyWith(
                                            color: TriageColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(
                                      width: TriageSpacing.sm,
                                    ), // pendiente a disponibilidad
                                    const TriageStatusBadge(
                                      label: 'Activo',
                                      dotColor: TriageColors.success,
                                      textColor: TriageColors.successText,
                                      background: TriageColors.surface,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const TriageIcon(
                              TriageIcons.checkCircle,
                              color: TriageColors.hospitalAccent,
                              size: TriageSizes.icon,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        TriageActionBar(
          primary: TriageButton(
            label: 'Continuar',
            onPressed: _selectedHospital == null
                ? null
                : () => setState(() => _currentStep = 3),
          ),
          secondary: TriageButton(
            label: 'Atrás',
            variant: TriageButtonVariant.subtle,
            onPressed: () => setState(() => _currentStep = 1),
          ),
        ),
      ],
    );
  }

  // --- PASO 3: CONFIRMACIÓN Y REGULACIÓN ---
  Widget _buildStep3Confirmation() {
    final List<String> unitsList = widget.ambulanceUnits;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(TriageSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TriagePatientStrip(
                level: widget.triageLevel,
                name: widget.patientFolio.isEmpty
                    ? widget.patientName
                    : '${widget.patientName} · ${widget.patientFolio}',
                detail: widget.conditionSummary,
              ),
              const SizedBox(height: TriageSpacing.lg),
              TriageSectionCard(
                trailing: TriageSectionAction(
                  label: 'Cambiar',
                  onTap: () {
                    if (_submitting) return;
                    setState(() {
                      _submitError = null;
                      _currentStep = 2;
                    });
                  },
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(TriageSpacing.sm),
                      decoration: BoxDecoration(
                        color: TriageColors.hospitalAccent,
                        borderRadius: BorderRadius.circular(TriageRadii.md),
                      ),
                      child: const TriageIcon(
                        TriageIcons.hospital,
                        color: TriageColors.textInverse,
                        size: TriageSizes.icon,
                      ),
                    ),
                    const SizedBox(width: TriageSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOSPITAL DESTINO',
                            style: TriageTextStyles.labelSmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                          Text(
                            _selectedHospital?.name ?? '',
                            style: TriageTextStyles.labelLarge,
                          ),
                          Text(
                            _selectedHospital?.address ??
                                'Sin dirección registrada',
                            style: TriageTextStyles.bodySmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TriageSpacing.lg),
              if (unitsList.isNotEmpty)
                TriageSelectField<String>(
                  label: 'Unidad de ambulancia',
                  value: _selectedUnit,
                  options: unitsList,
                  optionLabel: (String val) => val,
                  onChanged: (String? val) {
                    if (_submitting) return;
                    setState(() => _selectedUnit = val);
                  },
                ),
              const SizedBox(height: TriageSpacing.lg),
              TriageField(
                label: 'Folio de regulación (opcional)',
                hint: 'REG-00000',
                controller: _folioController,
              ),
              const SizedBox(height: TriageSpacing.xl),
              if (_submitError != null) ...[
                Container(
                  padding: const EdgeInsets.all(TriageSpacing.md),
                  decoration: BoxDecoration(
                    color: TriageColors.surface,
                    borderRadius: BorderRadius.circular(TriageRadii.md),
                    border: Border.all(color: TriageColors.dangerOnInverse),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: TriageColors.paramedicAccent,
                        size: 20,
                      ),
                      const SizedBox(width: TriageSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No se pudo confirmar el traslado',
                              style: TriageTextStyles.labelLarge.copyWith(
                                color: TriageColors.paramedicAccent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _submitError!,
                              style: TriageTextStyles.bodySmall.copyWith(
                                color: TriageColors.paramedicAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TriageSpacing.md),
              ],
              const TriageAlert(
                tone: TriageTone.warning,
                title: 'Al confirmar, el hospital recibe el aviso',
                message:
                    'El paciente pasa a "Trasladando" y el médico de guardia lo verá en su lista de entrantes.',
              ),
            ],
          ),
        ),
        TriageActionBar(
          primary: TriageButton(
            label: _submitting ? 'Confirmando...' : 'Confirmar traslado',
            onPressed: _submitting ? null : _finishTransfer,
          ),
          secondary: TriageButton(
            label: 'Atrás',
            variant: TriageButtonVariant.subtle,
            onPressed: _submitting
                ? null
                : () => setState(() {
                    _submitError = null;
                    _currentStep = 2;
                  }),
          ),
        ),
      ],
    );
  }

  // --- PASO 4: CONFIRMADO ---
  Widget _buildStep4Confirmed() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TriageSpacing.xl,
            vertical: TriageSpacing.lg,
          ),
          child: Column(
            children: [
              SizedBox.square(
                dimension: 64,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: TriageColors.hospitalSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: TriageIcon(
                      TriageIcons.ambulance,
                      size: 32,
                      color: TriageColors.hospitalAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TriageSpacing.md),
              Text(
                'En camino al hospital',
                style: TriageTextStyles.titleLarge.copyWith(
                  color: TriageColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TriageSpacing.xs),
              Text(
                'El ${_selectedHospital?.name ?? 'hospital'} ya fue notificado y verá al paciente en su lista de entrantes.',
                style: TriageTextStyles.bodyMedium.copyWith(
                  color: TriageColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TriageSpacing.xl),
              TriageSectionCard(
                child: Column(
                  children: [
                    TriageDataRow(
                      label: 'Hospital',
                      value: _selectedHospital?.name,
                    ),
                    const Divider(height: 1, color: TriageColors.borderSubtle),
                    TriageDataRow(label: 'Unidad', value: _selectedUnit),
                    const Divider(height: 1, color: TriageColors.borderSubtle),
                    TriageDataRow(label: 'Seguro', value: _insuranceLabel),
                    const Divider(height: 1, color: TriageColors.borderSubtle),
                    TriageDataRow(
                      label: 'Folio de regulación',
                      value: _folioController.text.trim().isEmpty
                          ? 'N/A'
                          : _folioController.text.trim(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        TriageActionBar(
          primary: TriageButton(
            label: 'Volver al incidente',
            onPressed: () => Navigator.pop(context, 'incident'),
          ),
          secondary: TriageButton(
            label: 'Ver ficha del paciente',
            variant: TriageButtonVariant.subtle,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}
