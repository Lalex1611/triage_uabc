import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Sustituye solamente la cámara nativa en las pruebas, nunca en producción.
class FakeQrCamera extends MobileScannerPlatform {
  final captures = StreamController<BarcodeCapture?>.broadcast();
  MobileScannerException? startError;
  Completer<void>? startGate;
  Completer<void>? stopGate;
  StartOptions? lastOptions;
  int starts = 0;
  int stops = 0;
  int disposals = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => captures.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts++;
    lastOptions = options;
    await startGate?.future;
    if (startError != null) throw startError!;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(640, 480),
      numberOfCameras: 1,
    );
  }

  @override
  Widget buildCameraView() => const ColoredBox(color: Color(0xFF222A35));
  @override
  Future<void> stop() async {
    stops++;
    await stopGate?.future;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }

  void detect(String raw, {BarcodeFormat format = BarcodeFormat.qrCode}) {
    captures.add(
      BarcodeCapture(
        barcodes: [Barcode(rawValue: raw, format: format)],
      ),
    );
  }
}

FakeQrCamera installFakeQrCamera() {
  final previous = MobileScannerPlatform.instance;
  final camera = FakeQrCamera();
  MobileScannerController.resetPlatformSessionOwner();
  MobileScannerPlatform.instance = camera;
  addTearDown(() async {
    MobileScannerController.resetPlatformSessionOwner();
    MobileScannerPlatform.instance = previous;
    await camera.captures.close();
  });
  return camera;
}
