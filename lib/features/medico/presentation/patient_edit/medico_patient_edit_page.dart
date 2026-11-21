import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_institution.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_walk_in_insurance.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_edit/medico_patient_edit_data.dart';
import 'package:sistema_triage/features/medico/domain/services/medico_patient_form_validators.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/widgets/medico_transfer_bottom_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';

/// Editar paciente en sala (menú "⋯" del mockup 06): identificación, seguro,
/// datos adicionales y signos vitales opcionales. Al guardar ejecuta [onSave];
/// si termina bien la pantalla se cierra con `true`.
class MedicoPatientEditPage extends StatefulWidget {
  const MedicoPatientEditPage({
    super.key,
    required this.folio,
    required this.initial,
    required this.onSave,
  });

  /// "PAC-…" para el encabezado
  final String folio;
  final MedicoPatientEditData initial;
  final Future<void> Function(MedicoPatientEditData data) onSave;

  @override
  State<MedicoPatientEditPage> createState() => _MedicoPatientEditPageState();
}

class _MedicoPatientEditPageState extends State<MedicoPatientEditPage> {
  late final _name = TextEditingController(text: widget.initial.displayName);
  late final _day = TextEditingController(
    text: widget.initial.birthDay?.toString() ?? '',
  );
  late final _month = TextEditingController(
    text: widget.initial.birthMonth?.toString() ?? '',
  );
  late final _year = TextEditingController(
    text: widget.initial.birthYear?.toString() ?? '',
  );
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _otherInstitution = TextEditingController(
    text:
        MedicoInsuranceInstitution.optionFor(widget.initial.institution) ==
                MedicoInsuranceInstitution.other &&
            widget.initial.institution != MedicoInsuranceInstitution.other
        ? widget.initial.institution
        : '',
  );
  late final _allergies = TextEditingController(text: widget.initial.allergies);
  late final _medications = TextEditingController(
    text: widget.initial.medications,
  );
  late final _history = TextEditingController(
    text: widget.initial.medicalHistory,
  );
  late final Map<String, TextEditingController> _vitals = {
    for (final k in MedicoPatientEditData.vitalKeys.keys)
      k: TextEditingController(text: widget.initial.vitals[k] ?? ''),
  };

  late MedicoPatientGender? _gender = widget.initial.gender;
  late PatientBloodType? _blood = widget.initial.bloodType;
  late MedicoWalkInInsurance? _insurance = widget.initial.insurance;
  late String? _institution = MedicoInsuranceInstitution.optionFor(
    widget.initial.institution,
  );

  bool _busy = false;
  String? _error;

  List<TextEditingController> get _all => [
    _name,
    _day,
    _month,
    _year,
    _phone,
    _otherInstitution,
    _allergies,
    _medications,
    _history,
    ..._vitals.values,
  ];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) {
      return 'Escribe el nombre del paciente o "desconocido".';
    }
    return MedicoPatientFormValidators.birthDateError(
          _day.text,
          _month.text,
          _year.text,
        ) ??
        MedicoPatientFormValidators.phoneError(_phone.text) ??
        (_insurance == MedicoWalkInInsurance.si &&
                _institution == MedicoInsuranceInstitution.other &&
                _otherInstitution.text.trim().isEmpty
            ? 'Escribe el nombre de la institución del seguro.'
            : null) ??
        (_vitals.values.every(
              (c) => MedicoPatientFormValidators.isValidVital(c.text),
            )
            ? null
            : 'Revisa los signos vitales: hay un valor que no es un número.');
  }

  MedicoPatientEditData _collect() {
    final institution = _institution == MedicoInsuranceInstitution.other
        ? _otherInstitution.text.trim()
        : (_institution ?? '');
    return MedicoPatientEditData(
      displayName: _name.text.trim(),
      birthDay: int.tryParse(_day.text.trim()),
      birthMonth: int.tryParse(_month.text.trim()),
      birthYear: int.tryParse(_year.text.trim()),
      gender: _gender,
      bloodType: _blood,
      phone: _phone.text.trim(),
      insurance: _insurance,
      institution: institution,
      allergies: _allergies.text,
      medications: _medications.text,
      medicalHistory: _history.text,
      vitals: {for (final e in _vitals.entries) e.key: e.value.text},
    );
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(_collect());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final m = RegExp(r'message: ([^,]+)').firstMatch('$e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = m?.group(1)?.trim() ?? '$e'.replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: MedicoWalkInColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: MedicoReviewHeader(
                title: 'Editar paciente',
                subtitle: '${widget.folio} · ${widget.initial.displayName}',
                leadingIcon: Icons.close,
                onBackTap: () {
                  if (!_busy) Navigator.of(context).pop(false);
                },
              ),
            ),
            Expanded(
              // Mientras se guarda no se puede seguir editando: lo que se
              // envía es lo que había al tocar "Guardar"
              child: AbsorbPointer(
                absorbing: _busy,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _identification(),
                    const SizedBox(height: 16),
                    _insuranceCard(),
                    const SizedBox(height: 16),
                    _additional(),
                    const SizedBox(height: 16),
                    _vitalsCard(),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            MedicoTransferBottomBar(
              primaryLabel: 'Guardar cambios',
              primaryColor: MedicoWalkInColors.primary,
              busy: _busy,
              onPrimaryTap: _save,
              onCancelTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identification() {
    return MedicoWalkInCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MedicoWalkInCardTitle('Identificación'),
          const SizedBox(height: 14),
          const MedicoWalkInLabel('Nombre completo'),
          MedicoWalkInTextField(
            controller: _name,
            hint: 'Escribe el nombre o "desconocido"',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          const MedicoWalkInLabel('Fecha de nacimiento (opcional)'),
          Row(
            children: [
              Expanded(
                child: MedicoWalkInTextField(
                  controller: _day,
                  hint: 'DD',
                  digitsOnly: true,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    MedicoWalkInMaxValueFormatter(max: 31, length: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MedicoWalkInTextField(
                  controller: _month,
                  hint: 'MM',
                  digitsOnly: true,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    MedicoWalkInMaxValueFormatter(max: 12, length: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MedicoWalkInTextField(
                  controller: _year,
                  hint: 'AAAA',
                  digitsOnly: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    MedicoWalkInMaxValueFormatter(
                      max: DateTime.now().year,
                      length: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MedicoWalkInLabel('Sexo'),
                    MedicoWalkInDropdown<MedicoPatientGender>(
                      value: _gender,
                      items: MedicoPatientGender.values,
                      labelOf: (g) => switch (g) {
                        MedicoPatientGender.masculino => 'Masculino',
                        MedicoPatientGender.femenino => 'Femenino',
                      },
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MedicoWalkInLabel('Tipo de sangre'),
                    MedicoWalkInDropdown<PatientBloodType>(
                      value: _blood,
                      items: PatientBloodType.values,
                      labelOf: (b) => b.label,
                      onChanged: (b) => setState(() => _blood = b),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MedicoWalkInLabel('Teléfono de contacto'),
          MedicoWalkInTextField(
            controller: _phone,
            hint: '664 000 0000',
            keyboardType: TextInputType.phone,
            maxLength: 18,
            inputFormatters: [MedicoWalkInPhoneFormatter()],
          ),
        ],
      ),
    );
  }

  Widget _insuranceCard() {
    return MedicoWalkInCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MedicoWalkInCardTitle('¿Cuenta con seguro médico?'),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final opt in MedicoWalkInInsurance.values) ...[
                if (opt != MedicoWalkInInsurance.values.first)
                  const SizedBox(width: 10),
                Expanded(
                  child: _Choice(
                    label: opt.label,
                    selected: _insurance == opt,
                    onTap: () => setState(() => _insurance = opt),
                  ),
                ),
              ],
            ],
          ),
          if (_insurance == MedicoWalkInInsurance.si) ...[
            const SizedBox(height: 16),
            const MedicoWalkInLabel('Institución del seguro'),
            MedicoWalkInDropdown<String>(
              value: _institution,
              items: MedicoInsuranceInstitution.options,
              labelOf: (s) => s,
              onChanged: (s) => setState(() => _institution = s),
            ),
            if (_institution == MedicoInsuranceInstitution.other) ...[
              const SizedBox(height: 10),
              MedicoWalkInTextField(
                controller: _otherInstitution,
                hint: 'Nombre de la institución',
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _additional() {
    return MedicoWalkInCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MedicoWalkInCardTitle('Datos adicionales'),
          const SizedBox(height: 14),
          const MedicoWalkInLabel('Alergias'),
          MedicoWalkInTextField(
            controller: _allergies,
            hint: 'Ej. penicilina, mariscos',
            maxLines: 2,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          const MedicoWalkInLabel('Medicamentos que usa'),
          MedicoWalkInTextField(
            controller: _medications,
            hint: 'Ej. metformina 850 mg cada 12 h',
            maxLines: 2,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          const MedicoWalkInLabel('Padecimientos a prevenir'),
          MedicoWalkInTextField(
            controller: _history,
            hint: 'Ej. diabetes tipo 2, hipertensión',
            maxLines: 2,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _vitalsCard() {
    Widget field(
      String label,
      String unit,
      String key, {
      bool decimal = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicoWalkInLabel(label),
          MedicoWalkInTextField(
            controller: _vitals[key]!,
            hint: unit,
            digitsOnly: !decimal,
            decimal: decimal,
            maxLength: 5,
          ),
        ],
      );
    }

    Widget row(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );

    return MedicoWalkInCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MedicoWalkInCardTitle('Signos vitales (opcional)'),
          const SizedBox(height: 14),
          row(
            field('T/A sistólica', 'mmHg', 'systolic_pressure'),
            field('T/A diastólica', 'mmHg', 'diastolic_pressure'),
          ),
          const SizedBox(height: 12),
          row(
            field('Frec. cardiaca', 'lpm', 'heart_rate'),
            field('Frec. respiratoria', 'rpm', 'respiratory_rate'),
          ),
          const SizedBox(height: 12),
          row(
            field('Temperatura', '°C', 'temperature', decimal: true),
            field('SpO₂', '%', 'oxygen_saturation'),
          ),
          const SizedBox(height: 12),
          row(field('Glucosa', 'mg/dL', 'glucose'), const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? MedicoWalkInColors.primary
          : MedicoWalkInColors.fieldFill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? MedicoWalkInColors.primary
                  : MedicoWalkInColors.fieldBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : MedicoWalkInColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
