import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/offline/offline_capture_store.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/medico/data/offline/medico_offline_runtime.dart';
import 'package:sistema_triage/shared/patient/consultation_code_qr_dialog.dart';
import 'package:sistema_triage/shared/widgets/offline_connection_page.dart';

class MedicoOfflinePage extends StatelessWidget {
  const MedicoOfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = MedicoOfflineRuntime.instance;
    void goBack() => context.canPop() ? context.pop() : context.go('/medico');

    return ListenableBuilder(
      listenable: runtime,
      builder: (context, _) => OfflineConnectionPage(
        canContinue: runtime.canCapture,
        connected: runtime.connected,
        error: runtime.error,
        onBack: goBack,
        onContinue: goBack,
        onRetry: runtime.retryNow,
        continueLabel: 'Volver a Médico',
        captureMessage:
            'Los registros de pacientes que llegan por su cuenta se guardan en este teléfono y se envían al recuperar la conexión.',
        pending: runtime.canCapture
            ? FutureBuilder<List<Capture>>(
                key: ValueKey(runtime.session),
                future: runtime.captures(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('No se pudieron leer los registros.');
                  }
                  final rows = snapshot.data;
                  if (rows == null) return const LinearProgressIndicator();
                  if (rows.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay registros guardados en este teléfono.',
                      ),
                    );
                  }
                  rows.sort(
                    (a, b) => (b['captured_at'] as String).compareTo(
                      a['captured_at'] as String,
                    ),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final row in rows)
                        _captureCard(context, runtime, row),
                    ],
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _captureCard(
    BuildContext context,
    MedicoOfflineRuntime runtime,
    Capture row,
  ) {
    final state = row['state'];
    final code = row['code'] as String?;
    final patient = row['remote_id'] as String?;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(captureTitle(row)),
            subtitle: Text(
              [captureStatus(row), ?row['message'] as String?].join('\n'),
            ),
            isThreeLine: row['message'] != null,
          ),
          if (state == 'attention')
            TextButton(
              onPressed: runtime.syncing || !runtime.connected
                  ? null
                  : () async {
                      try {
                        await runtime.retryReviewedCapture(row['id'] as String);
                      } catch (_) {
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            'No se pudo reintentar. El registro se conserva.',
                            isError: true,
                          );
                        }
                      }
                    },
              child: const Text('Reintentar registro revisado'),
            ),
          if (state == 'synced' && code != null)
            TextButton(
              onPressed: () =>
                  unawaited(ConsultationCodeQrDialog.show(context, code: code)),
              child: const Text('Código de consulta'),
            ),
          if (state == 'synced' && patient != null && runtime.connected)
            TextButton(
              onPressed: () =>
                  unawaited(context.push<void>('/medico/paciente/$patient')),
              child: const Text('Abrir paciente en Sala'),
            ),
        ],
      ),
    );
  }
}
