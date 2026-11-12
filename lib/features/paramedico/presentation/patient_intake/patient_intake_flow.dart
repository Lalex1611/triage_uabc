import 'package:flutter/material.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/assign_color_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_registered_dialog.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/register_patient_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/start_guided_sheet.dart';

/// Registro de pacientes desde un incidente: abre B11 y encadena el método elegido
///
/// Se muestra un solo panel a la vez: al elegir un método, B11 se cierra, y
/// pasar de START guiado a Asignar color (o al revés) cierra uno antes de abrir
/// el otro. [onPatientsChanged] se llama tras cada paciente guardado, también en
/// Emergencias. [openExtendedRegistration] abre de momento la pantalla actual
/// de registro completo.
Future<void> startPatientIntake(
  BuildContext context, {
  required String incidentId,
  required String subtitle,
  required VoidCallback onPatientsChanged,
  required Future<void> Function() openExtendedRegistration,
  PatientIntakeSession? session,
}) async {
  final intake = session ?? PatientIntakeSession(incidentId: incidentId);
  var option = await showRegisterPatientSheet(context, subtitle: subtitle);

  while (option != null && context.mounted) {
    if (option == PatientIntakeOption.extended) {
      await openExtendedRegistration();
      return;
    }

    try {
      await intake.prepare();
    } catch (e) {
      // START se puede responder sin conexión: al guardar se vuelve a
      // preparar y, si falla, el error sale en el panel
      if (option != PatientIntakeOption.startGuided && context.mounted) {
        showAppSnackBar(
          context,
          'No se pudo preparar el registro: $e',
          isError: true,
        );
      }
      if (option != PatientIntakeOption.startGuided) return;
    }
    if (!context.mounted) return;

    PatientIntakeOption? switchTo;
    final patient = option == PatientIntakeOption.startGuided
        ? await showStartGuidedSheet(
            context,
            session: intake,
            onAssignColor: () => switchTo = PatientIntakeOption.assignColor,
          )
        : await showAssignColorSheet(
            context,
            session: intake,
            emergency: option == PatientIntakeOption.emergency,
            onUseGuided: () => switchTo = PatientIntakeOption.startGuided,
            onRegistered: (_) => onPatientsChanged(),
          );
    if (switchTo != null) {
      option = switchTo;
      continue;
    }
    if (patient == null || !context.mounted) return;

    onPatientsChanged();
    final next = await showPatientRegisteredDialog(
      context,
      patient: patient,
      classifiedCount: intake.registeredCount,
    );
    if (!context.mounted) return;
    if (next == PatientRegisteredNext.record) {
      await pushParamedicoFullScreen(
        context,
        '/paramedico/patient/${patient.id}',
      );
      return;
    }
    // «Registrar siguiente» repite el mismo método
    if (next != PatientRegisteredNext.another) return;
  }
}
