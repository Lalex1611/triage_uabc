import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_code.dart';

/// Devuelve solamente el código leído. La consulta remota sigue a cargo de A04.
class ConsultaQrScreen extends StatefulWidget {
  const ConsultaQrScreen({super.key});

  @override
  State<ConsultaQrScreen> createState() => _ConsultaQrScreenState();
}

class _ConsultaQrScreenState extends State<ConsultaQrScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _camera;
  Future<void>? _startOperation;
  Future<void>? _stopOperation;
  bool _starting = false;
  bool _returning = false;
  bool _active = true;
  bool _unexpectedCameraError = false;
  String? _scanNotice;

  bool get _supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _active =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (_supported) {
      _camera = MobileScannerController(
        autoStart: false,
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      );
      WidgetsBinding.instance.addObserver(this);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_startCamera()),
      );
    }
  }

  Future<void> _startCamera() async {
    final camera = _camera;
    if (!mounted ||
        !_active ||
        _returning ||
        camera == null ||
        _starting ||
        camera.value.isRunning) {
      return;
    }
    setState(() => _unexpectedCameraError = false);
    _starting = true;
    var started = false;
    try {
      await _stopOperation;
      if (!mounted || !_active || _returning) return;
      final operation = camera.start();
      _startOperation = operation;
      await operation;
      started = camera.value.isRunning;
      if (!mounted || !_active || _returning) await _stopCamera();
    } catch (_) {
      if (mounted && !_returning) setState(() => _unexpectedCameraError = true);
    } finally {
      _startOperation = null;
      _starting = false;
      // Si se volvió a la app mientras terminaba la detención inicial,
      // no perder el reinicio solicitado por el evento resumed.
      if (started &&
          mounted &&
          _active &&
          !_returning &&
          !camera.value.isRunning) {
        unawaited(_startCamera());
      }
    }
  }

  Future<void> _stopCamera() async {
    if (_stopOperation != null) {
      try {
        await _stopOperation;
      } catch (_) {}
      return;
    }
    final operation = _camera?.stop();
    if (operation == null) return;
    _stopOperation = operation;
    try {
      await operation;
    } catch (_) {
      // La liberación final se realiza también al disponer el controlador.
    } finally {
      _stopOperation = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_returning || _camera == null) return;
    // El diálogo de permiso puede cambiar el ciclo de vida durante el arranque.
    if (!_camera!.value.hasCameraPermission) return;
    if (_active) {
      unawaited(_startCamera());
    } else {
      unawaited(_stopCamera());
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_returning || !_active) return;
    var hasContent = false;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      hasContent = true;
      if (barcode.format != BarcodeFormat.qrCode) continue;
      final code = ConsultaCode.normalize(raw);
      if (ConsultaCode.isValid(code)) {
        // Se bloquea antes del primer await para consumir una sola detección.
        _returning = true;
        unawaited(_returnCode(code));
        return;
      }
    }
    if (hasContent && _scanNotice == null) {
      setState(
        () => _scanNotice =
            'Este QR no contiene un código de consulta de seis caracteres. Apunta al QR entregado por el personal.',
      );
    }
  }

  Future<void> _returnCode(String code) async {
    await _stopCamera();
    if (mounted) Navigator.of(context).pop(code);
  }

  void _returnToManual() {
    if (_returning) return;
    _returning = true;
    unawaited(_stopCamera());
    Navigator.of(context).pop();
  }

  Future<void> _releaseCamera() async {
    // Si se sale mientras se solicita permiso, liberar también el arranque tardío.
    try {
      await _startOperation;
    } catch (_) {}
    await _stopCamera();
    try {
      await _camera?.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _returning = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_releaseCamera());
    super.dispose();
  }

  Widget _cameraError({
    bool permissionDenied = false,
    bool unsupported = false,
  }) {
    return ColoredBox(
      color: const Color(0xFF222A35),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              permissionDenied
                  ? Icons.no_photography_outlined
                  : Icons.videocam_off_outlined,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              permissionDenied
                  ? 'Permiso de cámara denegado'
                  : unsupported
                  ? 'Cámara no disponible'
                  : 'No pudimos iniciar la cámara',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              permissionDenied
                  ? 'Activa el permiso de cámara en los ajustes de la aplicación o escribe el código.'
                  : 'Puedes escribir el código para continuar con la consulta.',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                color: const Color(0xFFCDD4DD),
                fontSize: 14,
              ),
            ),
            if (_camera != null)
              TextButton(
                onPressed: () => unawaited(_startCamera()),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                child: const Text('Reintentar cámara'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    final camera = _camera;
    return CustomPaint(
      foregroundPainter: const _QrBorderPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: camera == null
            ? _cameraError(unsupported: true)
            : Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: camera,
                    useAppLifecycleState: false,
                    onDetect: _onDetect,
                    onDetectError: (_, _) {
                      if (mounted && !_returning) {
                        setState(
                          () => _scanNotice =
                              'No pudimos leer el QR. Ajusta la distancia o escribe el código.',
                        );
                      }
                    },
                    placeholderBuilder: (_) => const ColoredBox(
                      color: Color(0xFF222A35),
                      child: Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                    errorBuilder: (_, error) => _cameraError(
                      permissionDenied:
                          error.errorCode ==
                          MobileScannerErrorCode.permissionDenied,
                      unsupported:
                          error.errorCode == MobileScannerErrorCode.unsupported,
                    ),
                  ),
                  if (_unexpectedCameraError) _cameraError(),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<String>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _returning = true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF131A24),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 24, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Regresar',
                      onPressed: _returnToManual,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Escanear código',
                        style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final frameSize = math.min(
                      230.0,
                      math.max(0.0, constraints.maxWidth - 48),
                    );
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: frameSize,
                                    height: frameSize,
                                    child: _buildViewfinder(),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Apunta la cámara al código QR',
                                    textAlign: TextAlign.center,
                                    style:
                                        AppTextStyles
                                            .ESC_SemiBold_bodyMedium.copyWith(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    'Se detecta solo: no tienes que tocar nada.',
                                    textAlign: TextAlign.center,
                                    style:
                                        AppTextStyles
                                            .ESC_Regular_bodyMedium.copyWith(
                                          fontSize: 14,
                                          color: const Color(0xFFB9BDC4),
                                        ),
                                  ),
                                  if (_scanNotice != null) ...[
                                    const SizedBox(height: 16),
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _scanNotice!,
                                        textAlign: TextAlign.center,
                                        style:
                                            AppTextStyles
                                                .ESC_Regular_bodyMedium.copyWith(
                                              fontSize: 14,
                                              color: const Color(0xFFFFC9C9),
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _returnToManual,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF121924),
                          minimumSize: const Size.fromHeight(54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          side: const BorderSide(
                            color: Color(0xFFD4DCE5),
                            width: 1.25,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: AppTextStyles
                              .ESC_SemiBold_bodyMedium.copyWith(fontSize: 15),
                        ),
                        child: const Text('Mejor escribo el código'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrBorderPainter extends CustomPainter {
  const _QrBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1.5),
          const Radius.circular(28),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xFFE2E5E9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 26) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 13, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrBorderPainter oldDelegate) => false;
}
