import 'package:flutter/material.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/assign_color_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_intake_session.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/patient_registered_dialog.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_intake/register_patient_sheet.dart';

/// Registro de pacientes desde un incidente: abre B11 y encadena el método elegido
///
/// Se muestra un solo panel a la vez: al elegir un método, B11 se cierra.
/// [onPatientsChanged] se llama tras cada paciente guardado, también en
/// Emergencias. [openGuidedStart] y [openExtendedRegistration] abren de momento
/// las pantallas actuales de START y de registro completo.
Future<void> startPatientIntake(
  BuildContext context, {
  required String incidentId,
  required String subtitle,
  required VoidCallback onPatientsChanged,
  required Future<void> Function() openGuidedStart,
  required Future<void> Function() openExtendedRegistration,
  PatientIntakeSession? session,
}) async {
  final intake = session ?? PatientIntakeSession(incidentId: incidentId);
  var option = await showRegisterPatientSheet(context, subtitle: subtitle);

  while (option != null && context.mounted) {
    switch (option) {
      case PatientIntakeOption.startGuided:
        await openGuidedStart();
        return;
      case PatientIntakeOption.extended:
        await openExtendedRegistration();
        return;
      case PatientIntakeOption.assignColor:
      case PatientIntakeOption.emergency:
        try {
          await intake.prepare();
        } catch (e) {
          if (context.mounted) {
            showAppSnackBar(
              context,
              'No se pudo preparar el registro: $e',
              isError: true,
            );
          }
          return;
        }
        if (!context.mounted) return;

        var useGuided = false;
        final patient = await showAssignColorSheet(
          context,
          session: intake,
          emergency: option == PatientIntakeOption.emergency,
          onUseGuided: () => useGuided = true,
          onRegistered: (_) => onPatientsChanged(),
        );
        if (useGuided) {
          await openGuidedStart();
          return;
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
}
