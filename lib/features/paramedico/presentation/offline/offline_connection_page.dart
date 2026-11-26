import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/connectivity/app_connectivity_notifier.dart';
import 'package:sistema_triage/features/paramedico/data/offline/paramedico_offline_runtime.dart';
import 'package:sistema_triage/features/paramedico/data/offline/offline_capture_store.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

import 'package:sistema_triage/shared/widgets/offline_connection_page.dart';

export 'package:sistema_triage/shared/widgets/offline_connection_page.dart';

class OfflineConnectionFlowPage extends StatelessWidget {
  const OfflineConnectionFlowPage({super.key});
  @override
  Widget build(BuildContext context) {
    final runtime = ParamedicoOfflineRuntime.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([runtime, AppConnectivityNotifier.instance]),
      builder: (context, _) => OfflineConnectionPage(
        canContinue: runtime.canCapture,
        connected: !runtime.offline,
        error: runtime.error ?? runtime.syncService?.storageError,
        onRetry: runtime.retryNow,
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(runtime.canCapture ? '/paramedico/mapa' : '/auth'),
        onContinue: () =>
            context.canPop() ? context.pop() : context.go('/paramedico/mapa'),
        pending: runtime.canCapture
            ? FutureBuilder<CaptureReadResult>(
                key: ValueKey(runtime.account),
                future: runtime.captures(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'No se pudieron leer las capturas. Reintenta.',
                    );
                  }
                  final result = snapshot.data ?? emptyCaptureReadResult;
                  final rows = result.rows;
                  if (rows.isEmpty && result.unreadableIds.isEmpty) {
                    return const Text(
                      'No hay capturas guardadas en este teléfono.',
                      textAlign: TextAlign.center,
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
                      const Text(
                        'Capturas de esta cuenta',
                        style: TriageTextStyles.titleMedium,
                      ),
                      if (result.unreadableIds.isNotEmpty)
                        Text(unreadableCaptureMessage(result.unreadableIds)),
                      for (final row in rows)
                        Card(
                          child: ListTile(
                            title: Text(captureTitle(row)),
                            subtitle: Text(captureStatus(row)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/paramedico/captura/${row['id']}',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
