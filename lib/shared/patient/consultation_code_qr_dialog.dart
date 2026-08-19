import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Diálogo que despliega el código de consulta y su código QR
class ConsultationCodeQrDialog {
  ConsultationCodeQrDialog._();

  static Future<void> show(
    BuildContext context, {
    required String code,
    String title = 'Código de consulta',
    String confirmLabel = 'Cerrar',
    VoidCallback? onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: QrImageView(
                      data: code,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Código de consulta. Puede copiarlo o mostrar este QR al familiar.',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                }
              },
              child: const Text('Copiar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx, rootNavigator: true).pop();
                onConfirm?.call();
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }
}
