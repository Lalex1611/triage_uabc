import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Métodos de registro que ofrece B11
enum PatientIntakeOption { startGuided, assignColor, emergency, extended }

/// Panel B11 «Registrar paciente»: solo elige el método y se cierra
Future<PatientIntakeOption?> showRegisterPatientSheet(
  BuildContext context, {
  required String subtitle,
}) {
  return showTriageSheet<PatientIntakeOption>(
    context,
    title: 'Registrar paciente',
    subtitle: subtitle,
    builder: (sheetContext) {
      VoidCallback choose(PatientIntakeOption option) =>
          () => Navigator.pop(sheetContext, option);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TriageSpacing.xl,
              TriageSpacing.lg,
              TriageSpacing.xl,
              TriageSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TriageSpacing.md,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '¿Cómo lo vas a clasificar?',
                    style: TriageTextStyles.screenTitle.copyWith(
                      color: TriageColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Las tres formas registran al paciente. Elige la que te '
                  'deje avanzar más rápido en la escena.',
                  style: TriageTextStyles.bodyMedium.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                ),
                TriageLargeOption(
                  icon: TriageIcons.clipboard,
                  title: 'START guiado',
                  detail:
                      'Responde 4 o 5 preguntas cortas y el sistema propone el color.',
                  highlighted: true,
                  onTap: choose(PatientIntakeOption.startGuided),
                ),
                TriageLargeOption(
                  icon: TriageIcons.pulse,
                  title: 'Asignar color directo',
                  detail: 'Ya sabes la prioridad. Un toque y queda registrado.',
                  neutral: true,
                  onTap: choose(PatientIntakeOption.assignColor),
                ),
                const SizedBox(height: TriageSpacing.sm),
                TriageLargeOption(
                  icon: TriageIcons.alert,
                  title: 'Emergencias',
                  detail: 'Registra varios pacientes seguidos.',
                  tinted: true,
                  onTap: choose(PatientIntakeOption.emergency),
                ),
              ],
            ),
          ),
          TriageOptionRow(
            icon: TriageIcons.document,
            title: 'Registro extendido',
            detail: 'Captura todos los datos del paciente',
            onTap: choose(PatientIntakeOption.extended),
          ),
          const SizedBox(height: TriageSpacing.lg),
        ],
      );
    },
  );
}
