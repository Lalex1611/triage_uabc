import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

enum PatientRegisteredNext { another, record }

/// Diálogo «PAC-… quedó registrado». Devuelve `null` con «Volver al incidente»
Future<PatientRegisteredNext?> showPatientRegisteredDialog(
  BuildContext context, {
  required RegisteredPatient patient,
  required int classifiedCount,
}) {
  return showDialog<PatientRegisteredNext>(
    context: context,
    builder: (dialogContext) => TriageDialog(
      icon: TriageMessageIcon.level(TriageIcons.check, patient.level),
      title: '${patient.folio} quedó registrado',
      message: classifiedCount == 1
          ? 'Va 1 paciente clasificado en este incidente.'
          : 'Van $classifiedCount pacientes clasificados en este incidente.',
      content: Center(child: TriageLevelPill(patient.level)),
      actions: [
        TriageButton(
          label: 'Registrar siguiente paciente',
          onPressed: () =>
              Navigator.pop(dialogContext, PatientRegisteredNext.another),
        ),
        TriageButton(
          label: 'Ver la ficha del paciente',
          variant: TriageButtonVariant.secondary,
          onPressed: () =>
              Navigator.pop(dialogContext, PatientRegisteredNext.record),
        ),
        TriageButton(
          label: 'Volver al incidente',
          variant: TriageButtonVariant.subtle,
          size: TriageButtonSize.medium,
          onPressed: () => Navigator.pop(dialogContext),
        ),
      ],
    ),
  );
}
