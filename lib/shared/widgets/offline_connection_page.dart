import 'package:flutter/material.dart';
import 'package:sistema_triage/core/offline/offline_capture_store.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

String captureStatus(Capture row) => switch (row['state']) {
  'synced' => 'Sincronizado',
  'syncing' => 'Sincronizando',
  'attention' => 'Requiere atención',
  _ => 'Guardado en este dispositivo',
};
String captureTitle(Capture row) {
  final payload = row['payload'] as Map;
  final title =
      (payload[row['kind'] == 'incident' ? 'title' : 'display_name'] as String?)
          ?.trim();
  return title?.isNotEmpty == true
      ? title!
      : 'Paciente · ${(row['id'] as String).substring(0, 8).toUpperCase()}';
}

String unreadableCaptureMessage(List<String> ids) =>
    'No se pudieron leer estas capturas. Se conservan para recuperación: ${ids.join(', ')}';

/// A08 ofrece la captura local cuando el almacenamiento está listo y la sesión
/// ya se verificó.
class OfflineConnectionPage extends StatefulWidget {
  const OfflineConnectionPage({
    super.key,
    required this.canContinue,
    required this.connected,
    required this.onRetry,
    required this.onBack,
    this.onContinue,
    this.pending = const SizedBox.shrink(),
    this.error,
    this.captureMessage,
    this.continueLabel,
  });
  final bool canContinue;
  final bool connected;
  final Future<void> Function() onRetry;
  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final Widget pending;
  final String? error;
  final String? captureMessage;
  final String? continueLabel;
  @override
  State<OfflineConnectionPage> createState() => _OfflineConnectionPageState();
}

class _OfflineConnectionPageState extends State<OfflineConnectionPage> {
  bool _retrying = false;
  String? _error;
  Future<void> _retry() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _error = null;
    });
    try {
      await widget.onRetry();
    } catch (_) {
      _error = 'No se pudo completar el reintento. Tus capturas se conservan.';
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TriageColors.canvas,
    body: Column(
      children: [
        TriageDetailHeader(
          title: widget.connected ? 'Conexión y capturas' : 'Sin conexión',
          subtitle: _retrying ? 'Reintentando…' : null,
          onBack: widget.onBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TriageSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: TriageColors.warningBackground,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const TriageIcon(
                      TriageIcons.offline,
                      size: 40,
                      color: TriageColors.warningText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.connected ? 'Conexión disponible' : 'No hay conexión',
                  textAlign: TextAlign.center,
                  style: TriageTextStyles.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.canContinue
                      ? widget.captureMessage ??
                            'Lo que captures se guarda en el dispositivo y se envía cuando el servidor esté disponible con tu sesión autorizada. Puedes seguir trabajando.'
                      : 'Necesitas iniciar sesión con conexión para acceder a las capturas de tu cuenta en este dispositivo.',
                  textAlign: TextAlign.center,
                  style: TriageTextStyles.bodyMedium,
                ),
                if (widget.canContinue) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Puedes consultar las capturas en Conexión y capturas durante 24 horas después de sincronizarlas. Luego se borran del dispositivo.',
                    textAlign: TextAlign.center,
                    style: TriageTextStyles.bodyMedium,
                  ),
                ],
                if (widget.error != null || _error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error ?? widget.error!,
                      style: const TextStyle(color: TriageColors.danger),
                    ),
                  ),
                const SizedBox(height: 24),
                widget.pending,
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(TriageSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TriageButton(
                  label: _retrying ? 'Reintentando…' : 'Reintentar ahora',
                  onPressed: _retrying ? null : _retry,
                ),
                const SizedBox(height: 12),
                TriageButton(
                  label: widget.canContinue
                      ? widget.continueLabel ?? 'Seguir sin conexión'
                      : 'Volver al acceso',
                  variant: TriageButtonVariant.subtle,
                  onPressed: widget.canContinue
                      ? widget.onContinue
                      : widget.onBack,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 3,
          width: double.infinity,
          child: ColoredBox(color: TriageColors.info),
        ),
      ],
    ),
  );
}
