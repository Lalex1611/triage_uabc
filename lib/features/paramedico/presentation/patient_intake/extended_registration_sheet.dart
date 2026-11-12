import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_gender.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_injury_type.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_widgets.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Panel «Registro extendido» (B12): color, fotos, datos personales y lesiones
///
/// Devuelve el paciente registrado. Guarda en `demographics` las mismas claves
/// que la pantalla de registro anterior, que son las que leen la ficha y su
/// edición. Con datos escritos, cerrar pide confirmación; por eso no se cierra
/// tocando fuera ni arrastrando.
Future<RegisteredPatient?> showExtendedRegistrationSheet(
  BuildContext context, {
  required PatientIntakeSession session,
}) {
  return showTriageSheetWith<RegisteredPatient>(
    context,
    dismissible: false,
    sheetBuilder: (_) => ExtendedRegistrationPanel(session: session),
  );
}

@visibleForTesting
class ExtendedRegistrationPanel extends StatefulWidget {
  const ExtendedRegistrationPanel({super.key, required this.session});

  final PatientIntakeSession session;

  @override
  State<ExtendedRegistrationPanel> createState() =>
      _ExtendedRegistrationPanelState();
}

class _ExtendedRegistrationPanelState extends State<ExtendedRegistrationPanel> {
  static const _maxAge = 120;

  TriageLevel? _level;
  final List<String> _photos = [];
  String _name = '';
  String _age = '';
  PatientGender? _gender;
  PatientBloodType? _bloodType;
  String _phone = '';
  String _description = '';
  final Set<PatientInjuryType> _injuries = {};
  bool _saving = false;
  String? _error;

  /// Años escritos; `null` si el campo está vacío
  int? get _ageYears => int.tryParse(_age.trim());

  String? get _ageError {
    if (_age.trim().isEmpty) return null;
    final years = _ageYears;
    return years == null || years < 0 || years > _maxAge
        ? 'Escribe la edad en años'
        : null;
  }

  bool get _hasData =>
      _level != null ||
      _photos.isNotEmpty ||
      [_name, _age, _phone, _description].any((v) => v.trim().isNotEmpty) ||
      _gender != null ||
      _bloodType != null ||
      _injuries.isNotEmpty;

  Map<String, Object?> _details() {
    final years = _ageYears;
    final phone = _phone.trim();
    final description = _description.trim();
    return {
      if (description.isNotEmpty) 'description': description,
      if (_injuries.isNotEmpty)
        'injury_types': [for (final i in _injuries) i.name],
      if (_gender != null) 'gender': _gender!.name,
      if (_bloodType != null) 'blood_type': _bloodType!.name,
      // La ficha calcula la edad con el año de nacimiento
      if (years != null) 'birth_year': DateTime.now().year - years,
      if (phone.isNotEmpty) 'emergency_contact': phone,
    };
  }

  Future<void> _requestClose() async {
    if (_saving) return;
    if (!_hasData) {
      Navigator.pop(context);
      return;
    }
    if (await confirmDiscardPatient(context) && mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final level = _level;
    if (level == null || _ageError != null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final patient = await widget.session.register(
        level: level,
        name: _name,
        photos: _photos,
        mode: null,
        details: _details(),
      );
      if (mounted) Navigator.pop(context, patient);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _genderLabel(PatientGender gender) => switch (gender) {
    PatientGender.masculino => 'Masculino',
    PatientGender.femenino => 'Femenino',
  };

  @override
  Widget build(BuildContext context) {
    final error = _error;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: TriageSheet(
        title: 'Registro extendido',
        subtitle:
            'Paciente ${widget.session.nextNumber} · '
            '${widget.session.incidentFolio}',
        onClose: _requestClose,
        showGrip: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  TriageSpacing.xl,
                  TriageSpacing.lg,
                  TriageSpacing.xl,
                  TriageSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: TriageSpacing.lg,
                  children: [
                    _SectionTitle('Clasificación TRIAGE'),
                    StartLevelGrid(
                      selected: _level,
                      onSelected: (level) => setState(() => _level = level),
                    ),
                    IntakePhotos(
                      photos: _photos,
                      onAdded: (path) {
                        if (mounted) setState(() => _photos.add(path));
                      },
                    ),
                    TriageSectionCard(
                      title: 'Datos personales (opcional)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: TriageSpacing.lg,
                        children: [
                          TriageField(
                            label: 'Nombre o alias',
                            hint: 'Si lo conoces, escríbelo',
                            textInputAction: TextInputAction.next,
                            onChanged: (value) => setState(() => _name = value),
                          ),
                          TriageField(
                            label: 'Edad',
                            hint: 'Años',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            errorText: _ageError,
                            onChanged: (value) => setState(() => _age = value),
                          ),
                          TriageSelectField<PatientGender>(
                            label: 'Sexo',
                            hint: 'Sin especificar',
                            options: PatientGender.values,
                            optionLabel: _genderLabel,
                            value: _gender,
                            onChanged: (value) =>
                                setState(() => _gender = value),
                          ),
                          TriageSelectField<PatientBloodType>(
                            label: 'Tipo de sangre',
                            hint: 'Sin especificar',
                            options: PatientBloodType.values,
                            optionLabel: (blood) => blood.label,
                            value: _bloodType,
                            onChanged: (value) =>
                                setState(() => _bloodType = value),
                          ),
                          TriageField(
                            label: 'Teléfono de contacto',
                            hint: 'Familiar o persona a avisar',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onChanged: (value) =>
                                setState(() => _phone = value),
                          ),
                        ],
                      ),
                    ),
                    TriageSectionCard(
                      title: 'Estado y lesiones',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: TriageSpacing.md,
                        children: [
                          TriageField.area(
                            label: 'Descripción',
                            hint: 'Qué observas: lesiones, consciencia…',
                            onChanged: (value) =>
                                setState(() => _description = value),
                          ),
                          Wrap(
                            spacing: TriageSpacing.sm,
                            children: [
                              for (final injury in PatientInjuryType.values)
                                TriageChip(
                                  label: injury.label,
                                  selected: _injuries.contains(injury),
                                  onTap: () => setState(
                                    () => _injuries.contains(injury)
                                        ? _injuries.remove(injury)
                                        : _injuries.add(injury),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (error != null)
                      TriageAlert(
                        tone: TriageTone.danger,
                        title: 'No se pudo registrar al paciente',
                        message: error,
                      ),
                  ],
                ),
              ),
            ),
            TriageActionBar(
              secondary: TriageButton(
                label: 'Cancelar',
                variant: TriageButtonVariant.secondary,
                onPressed: _saving ? null : _requestClose,
              ),
              primary: TriageButton(
                label: 'Guardar paciente',
                isLoading: _saving,
                onPressed: _level == null || _ageError != null ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TriageTextStyles.labelLarge.copyWith(
          color: TriageColors.textPrimary,
        ),
      ),
    );
  }
}
