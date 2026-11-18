import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_insurance_institution.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_gender.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_walk_in_insurance.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_walk_in_identification_data.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_walk_in_form_widgets.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_blood_type.dart';

/// Paso 1 del registro sin traslado (mockup 07): foto opcional, identificación
/// y seguro médico.
class MedicoWalkInIdentificationStep extends StatelessWidget {
  const MedicoWalkInIdentificationStep({super.key, required this.data});

  final MedicoWalkInIdentificationData data;

  static String _genderLabel(MedicoPatientGender g) => switch (g) {
    MedicoPatientGender.masculino => 'Masculino',
    MedicoPatientGender.femenino => 'Femenino',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _photoRow(),
        const SizedBox(height: 18),
        MedicoWalkInCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MedicoWalkInCardTitle('Identificación'),
              const SizedBox(height: 14),
              const MedicoWalkInLabel('Nombre completo'),
              MedicoWalkInTextField(
                controller: data.nameController,
                hint: 'Escribe el nombre o "desconocido"',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              const MedicoWalkInLabel('Fecha de nacimiento (opcional)'),
              Row(
                children: [
                  Expanded(
                    child: MedicoWalkInTextField(
                      controller: data.birthDayController,
                      hint: 'DD',
                      digitsOnly: true,
                      maxLength: 2,
                      inputFormatters: [
                        MedicoWalkInMaxValueFormatter(max: 31, length: 2),
                      ],
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MedicoWalkInTextField(
                      controller: data.birthMonthController,
                      hint: 'MM',
                      digitsOnly: true,
                      maxLength: 2,
                      inputFormatters: [
                        MedicoWalkInMaxValueFormatter(max: 12, length: 2),
                      ],
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MedicoWalkInTextField(
                      controller: data.birthYearController,
                      hint: 'AAAA',
                      digitsOnly: true,
                      maxLength: 4,
                      inputFormatters: [
                        MedicoWalkInMaxValueFormatter(
                          max: DateTime.now().year,
                          length: 4,
                        ),
                      ],
                      textAlign: TextAlign.center,
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
                          value: data.gender,
                          items: MedicoPatientGender.values,
                          labelOf: _genderLabel,
                          onChanged: data.onGenderChanged,
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
                          value: data.bloodType,
                          items: PatientBloodType.values,
                          labelOf: (b) => b.label,
                          onChanged: data.onBloodTypeChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const MedicoWalkInLabel('Teléfono de contacto'),
              MedicoWalkInTextField(
                controller: data.phoneController,
                hint: '664 000 0000',
                keyboardType: TextInputType.phone,
                maxLength: 18,
                inputFormatters: [MedicoWalkInPhoneFormatter()],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MedicoWalkInCard(
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
                      child: _InsuranceOption(
                        label: opt.label,
                        selected: data.insurance == opt,
                        onTap: () => data.onInsuranceChanged(opt),
                      ),
                    ),
                  ],
                ],
              ),
              if (data.insurance == MedicoWalkInInsurance.si) ...[
                const SizedBox(height: 16),
                const MedicoWalkInLabel('Institución'),
                MedicoWalkInDropdown<String>(
                  value: data.institution,
                  items: MedicoInsuranceInstitution.options,
                  labelOf: (s) => s,
                  hint: 'Selecciona la institución',
                  onChanged: data.onInstitutionChanged,
                ),
                if (data.institution == MedicoInsuranceInstitution.other) ...[
                  const SizedBox(height: 10),
                  MedicoWalkInTextField(
                    controller: data.otherInstitutionController,
                    hint: 'Nombre de la institución',
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoRow() {
    final path = data.photoPath;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: path == null
              ? _AddPhotoBox(onTap: data.onAddPhotoTap)
              : _PhotoThumb(path: path, onRemoveTap: data.onRemovePhotoTap),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fotografía del paciente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MedicoWalkInColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Opcional, pero ayuda a identificarlo si no trae documentos '
                'o no puede hablar.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: MedicoWalkInColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoBox extends StatelessWidget {
  const _AddPhotoBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4E9EF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _DashedRRectPainter(),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 22,
                  color: MedicoWalkInColors.textSecondary,
                ),
                SizedBox(height: 6),
                Text(
                  'Añadir',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: MedicoWalkInColors.textSecondary,
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

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.path, required this.onRemoveTap});

  final String path;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final Widget image = kIsWeb
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.black87,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemoveTap,
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsuranceOption extends StatelessWidget {
  const _InsuranceOption({
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

class _DashedRRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB4BFCA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
