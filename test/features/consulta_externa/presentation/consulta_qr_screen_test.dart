import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:postgrest/postgrest.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/data/repositories/consulta_repository.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_rate_limit_exception.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_input_screen.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_qr_screen.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_status_screen.dart';

import '../support/fake_qr_camera.dart';

class _QrRepository extends ConsultaRepository {
  final Future<ConsultaLookupResult> Function(String) respond;
  final codes = <String>[];
  _QrRepository(this.respond);

  @override
  Future<ConsultaLookupResult> lookupByCode(String code) {
    codes.add(code);
    return respond(code);
  }
}

void main() {
  late FakeQrCamera camera;
  const photoChannel = MethodChannel('plugins.flutter.io/image_picker');
  late Future<String?> Function() pickPhoto;
  final photoCalls = <MethodCall>[];

  setUp(() {
    camera = installFakeQrCamera();
    photoCalls.clear();
    pickPhoto = () async => '/test/qr.png';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(photoChannel, (call) {
          expect(call.method, 'pickImage');
          if (camera.startError == null) {
            expect(camera.stops, greaterThan(0));
          }
          photoCalls.add(call);
          return pickPhoto();
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(photoChannel, null);
    });
    SupabaseEnv.applyRuntimeFallback(
      url: 'https://consulta.example.test',
      anonKey: 'test-only-key',
    );
  });

  _QrRepository successfulRepository() => _QrRepository(
    (code) async => ConsultaLookupResult(
      status: ConsultaStatus.recibido,
      code: code,
      hospitalName: 'Hospital de la consulta QR',
    ),
  );

  Future<void> pumpInput(
    WidgetTester tester,
    _QrRepository repository, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/consulta-externa',
      routes: [
        GoRoute(
          path: '/consulta-externa',
          builder: (_, _) => ConsultaInputScreen(repository: repository),
        ),
        GoRoute(
          path: '/consulta-status',
          builder: (_, state) => ConsultaStatusScreen(
            result: state.extra! as ConsultaLookupResult,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: appTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openScanner(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Escanear código QR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear código QR'));
    await tester.pumpAndSettle();
    expect(find.byType(ConsultaQrScreen), findsOneWidget);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  BarcodeCapture photoCapture(String value) => BarcodeCapture(
    barcodes: [Barcode(rawValue: value, format: BarcodeFormat.qrCode)],
  );

  Future<void> choosePhoto(WidgetTester tester) async {
    await tester.tap(find.text('Elegir foto del QR'));
    await tester.pumpAndSettle();
  }

  Future<File> pickedCachePhoto(WidgetTester tester) async {
    const cacheChannel = MethodChannel('plugins.flutter.io/path_provider');
    late Directory root;
    late Directory base;
    late Directory cache;
    final file = await tester.runAsync(() async {
      base = await Directory(
        'build/consulta_qr_screen_cleanup_tests',
      ).absolute.create(recursive: true);
      root = await base.createTemp('case-');
      cache = await Directory(p.join(root.path, 'cache')).create();
      final photo = File(
        p.join(cache.path, '11111111-2222-4333-8444-555555555555', 'QR.png'),
      );
      await photo.parent.create();
      await photo.writeAsString('copia temporal de prueba');
      await File(
        p.join(root.path, 'original.png'),
      ).writeAsString('original de prueba');
      return photo;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(cacheChannel, (call) async {
          expect(call.method, 'getTemporaryDirectory');
          return cache.path;
        });
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(cacheChannel, null);
      final basePath = await base.resolveSymbolicLinks();
      final rootPath = await root.resolveSymbolicLinks();
      if (!p.isWithin(basePath, rootPath)) {
        throw StateError('Limpieza fuera de las pruebas');
      }
      await Directory(rootPath).delete(recursive: true);
    });
    pickPhoto = () async => file!.path;
    return file!;
  }

  Future<void> waitForCleanup(WidgetTester tester, File file) async {
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (await file.exists()) {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('No se borró la copia temporal');
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'La copia temporal se elimina antes de consultar y el original permanece',
    (tester) async {
      final photo = await pickedCachePhoto(tester);
      final original = File(
        p.join(photo.parent.parent.parent.path, 'original.png'),
      );
      camera.imageCapture = photoCapture('AB3K7X');
      final repo = _QrRepository((code) async {
        expect(photo.existsSync(), isFalse);
        expect(original.existsSync(), isTrue);
        return ConsultaLookupResult(
          status: ConsultaStatus.recibido,
          code: code,
        );
      });
      await pumpInput(tester, repo);
      await openScanner(tester);
      await tester.runAsync(() => tester.tap(find.text('Elegir foto del QR')));
      await tester.pump();
      await waitForCleanup(tester, photo);
      expect(repo.codes, ['AB3K7X']);
      expect(find.text('Código AB3K7X'), findsOneWidget);
      await close(tester);
    },
  );

  testWidgets('Un error de análisis también elimina la copia temporal', (
    tester,
  ) async {
    final photo = await pickedCachePhoto(tester);
    camera.imageError = Exception('Imagen dañada');
    final repo = successfulRepository();
    await pumpInput(tester, repo);
    await openScanner(tester);
    await tester.runAsync(() => tester.tap(find.text('Elegir foto del QR')));
    await tester.pump();
    await waitForCleanup(tester, photo);
    expect(repo.codes, isEmpty);
    expect(find.textContaining('No pudimos leer la foto'), findsOneWidget);
    await close(tester);
  });

  testWidgets('Una foto recibida después de salir se limpia sin analizarla', (
    tester,
  ) async {
    final photo = await pickedCachePhoto(tester);
    final pending = Completer<String?>();
    pickPhoto = () => pending.future;
    final repo = successfulRepository();
    await pumpInput(tester, repo);
    await openScanner(tester);
    await tester.runAsync(() => tester.tap(find.text('Elegir foto del QR')));
    await tester.pump();
    await tester.tap(find.text('Mejor escribo el código'));
    await tester.pumpAndSettle();
    pending.complete(photo.path);
    await tester.pump();
    await waitForCleanup(tester, photo);
    expect(camera.analyzedImages, isEmpty);
    expect(repo.codes, isEmpty);
    await close(tester);
  });

  testWidgets(
    'Salir durante el análisis espera al resultado antes de borrar la copia',
    (tester) async {
      final photo = await pickedCachePhoto(tester);
      camera.imageGate = Completer<BarcodeCapture?>();
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      await tester.runAsync(() => tester.tap(find.text('Elegir foto del QR')));
      await tester.pump();
      expect(camera.analyzedImages, [photo.path]);
      expect(photo.existsSync(), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(photo.existsSync(), isTrue);
      camera.imageGate!.complete(photoCapture('AB3K7X'));
      await tester.pump();
      await waitForCleanup(tester, photo);
      expect(repo.codes, isEmpty);
      expect(camera.disposals, greaterThan(0));
      await close(tester);
    },
  );

  testWidgets(
    'Si no se puede verificar la caché se informa el fallo de limpieza',
    (tester) async {
      final photo = await pickedCachePhoto(tester);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async {
              throw PlatformException(code: 'cache_unavailable');
            },
          );
      camera.imageCapture = photoCapture('AB3K7X');
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      await tester.runAsync(() => tester.tap(find.text('Elegir foto del QR')));
      await tester.pump();
      for (
        var i = 0;
        i < 100 &&
            find
                .textContaining('No pudimos eliminar la copia temporal')
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No pudimos eliminar la copia temporal'),
        findsOneWidget,
      );
      expect(photo.existsSync(), isTrue);
      expect(repo.codes, isEmpty);
      await close(tester);
    },
  );

  testWidgets('Una foto con QR consulta el código normalizado una sola vez', (
    tester,
  ) async {
    final repo = successfulRepository();
    camera.imageCapture = photoCapture('ab-3k7x');
    await pumpInput(tester, repo);
    await openScanner(tester);
    await choosePhoto(tester);
    expect(repo.codes, ['AB3K7X']);
    expect(camera.analyzedImages, ['/test/qr.png']);
    expect(camera.imageFormats, [BarcodeFormat.qrCode]);
    expect(
      photoCalls.single.arguments,
      containsPair('source', ImageSource.gallery.index),
    );
    expect(
      photoCalls.single.arguments,
      containsPair('requestFullMetadata', false),
    );
    expect(find.text('Código AB3K7X'), findsOneWidget);
    expect(camera.disposals, greaterThan(0));
    await close(tester);
  });

  testWidgets('Un código inexistente leído de una foto termina en A07', (
    tester,
  ) async {
    camera.imageCapture = photoCapture('AB3K7X');
    final repo = _QrRepository(
      (_) async => throw const PostgrestException(
        message: 'not_found',
        code: 'not_found',
      ),
    );
    await pumpInput(tester, repo);
    await openScanner(tester);
    await choosePhoto(tester);
    expect(repo.codes, ['AB3K7X']);
    expect(find.text('El código no existe o ya venció'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'AB3K7X',
    );
    await close(tester);
  });

  testWidgets(
    'Elegir foto espera el arranque pendiente y reanuda la cámara al cancelar',
    (tester) async {
      camera.startGate = Completer<void>();
      pickPhoto = () async => null;
      await pumpInput(tester, successfulRepository());
      await openScanner(tester);
      await tester.tap(find.text('Elegir foto del QR'));
      await tester.pump();
      expect(photoCalls, isEmpty);
      camera.startGate!.complete();
      await tester.pumpAndSettle();
      expect(photoCalls, hasLength(1));
      expect(camera.starts, 2);
      await close(tester);
    },
  );

  testWidgets('Cancelar la galería conserva el código y reanuda la cámara', (
    tester,
  ) async {
    pickPhoto = () async => null;
    final repo = successfulRepository();
    await pumpInput(tester, repo);
    await tester.enterText(find.byType(TextField), 'CD4P9Z');
    await openScanner(tester);
    await choosePhoto(tester);
    expect(camera.analyzedImages, isEmpty);
    expect(camera.starts, 2);
    expect(repo.codes, isEmpty);
    await tester.tap(find.text('Mejor escribo el código'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'CD4P9Z',
    );
    await close(tester);
  });

  for (final raw in <String?>[
    null,
    '',
    'ABCDEFG',
    'https://ejemplo.test/AB3K7X',
    'AB!K7X',
  ]) {
    testWidgets('Foto sin QR válido permite elegir otra imagen: $raw', (
      tester,
    ) async {
      final repo = successfulRepository();
      camera.imageCapture = raw == null ? null : photoCapture(raw);
      await pumpInput(tester, repo);
      await openScanner(tester);
      await choosePhoto(tester);
      expect(repo.codes, isEmpty);
      expect(find.textContaining('No encontramos un QR'), findsOneWidget);
      expect(camera.starts, 2);
      camera.imageCapture = photoCapture('CD4P9Z');
      await choosePhoto(tester);
      expect(repo.codes, ['CD4P9Z']);
      await close(tester);
    });
  }

  testWidgets('Una foto con varios códigos distintos solicita otra imagen', (
    tester,
  ) async {
    final repo = successfulRepository();
    camera.imageCapture = BarcodeCapture(
      barcodes: [
        Barcode(rawValue: 'AB3K7X', format: BarcodeFormat.qrCode),
        Barcode(rawValue: 'CD4P9Z', format: BarcodeFormat.qrCode),
      ],
    );
    await pumpInput(tester, repo);
    await openScanner(tester);
    await choosePhoto(tester);
    expect(repo.codes, isEmpty);
    expect(find.textContaining('varios códigos'), findsOneWidget);
    await close(tester);
  });

  testWidgets('El mismo QR repetido en una foto produce una sola consulta', (
    tester,
  ) async {
    final repo = successfulRepository();
    camera.imageCapture = BarcodeCapture(
      barcodes: [
        Barcode(rawValue: 'AB3K7X', format: BarcodeFormat.qrCode),
        Barcode(rawValue: 'ab3k7x', format: BarcodeFormat.qrCode),
        Barcode(rawValue: 'CD4P9Z', format: BarcodeFormat.code128),
      ],
    );
    await pumpInput(tester, repo);
    await openScanner(tester);
    await choosePhoto(tester);
    expect(repo.codes, ['AB3K7X']);
    await close(tester);
  });

  for (final code in ['photo_access_denied', 'photo_access_restricted']) {
    testWidgets('Permiso de fotos $code conserva cámara e ingreso manual', (
      tester,
    ) async {
      pickPhoto = () async => throw PlatformException(code: code);
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      await choosePhoto(tester);
      expect(repo.codes, isEmpty);
      expect(camera.starts, 2);
      expect(
        find.textContaining('Permite el acceso a tus fotos'),
        findsOneWidget,
      );
      expect(
        find.text('Mejor escribo el código').hitTestable(),
        findsOneWidget,
      );
      await close(tester);
    });
  }

  for (final error in [
    Exception('Imagen dañada'),
    UnsupportedError('Simulador'),
  ]) {
    testWidgets('Un fallo de lectura de foto permite continuar: $error', (
      tester,
    ) async {
      camera.imageError = error;
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      await choosePhoto(tester);
      expect(repo.codes, isEmpty);
      expect(camera.starts, 2);
      expect(
        find.textContaining(
          error is UnsupportedError
              ? 'no está disponible'
              : 'No pudimos leer la foto',
        ),
        findsOneWidget,
      );
      await close(tester);
    });
  }

  testWidgets('La foto permite consultar aunque se haya denegado la cámara', (
    tester,
  ) async {
    camera.startError = const MobileScannerException(
      errorCode: MobileScannerErrorCode.permissionDenied,
    );
    camera.imageCapture = photoCapture('AB3K7X');
    final repo = successfulRepository();
    await pumpInput(tester, repo);
    await openScanner(tester);
    await choosePhoto(tester);
    expect(repo.codes, ['AB3K7X']);
    expect(camera.starts, 1);
    await close(tester);
  });

  testWidgets(
    'La galería bloquea lecturas de cámara y no reinicia al volver de segundo plano',
    (tester) async {
      final pending = Completer<String?>();
      pickPhoto = () => pending.future;
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      await tester.tap(find.text('Elegir foto del QR'));
      await tester.pump();
      camera.detect('AB3K7X');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(camera.starts, 1);
      expect(photoCalls, hasLength(1));
      expect(repo.codes, isEmpty);
      expect(find.text('Leyendo foto…'), findsOneWidget);
      pending.complete(null);
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      await close(tester);
    },
  );

  testWidgets('Salir de A05 durante la selección ignora la foto tardía', (
    tester,
  ) async {
    final pending = Completer<String?>();
    pickPhoto = () => pending.future;
    final repo = successfulRepository();
    await pumpInput(tester, repo);
    await openScanner(tester);
    await tester.tap(find.text('Elegir foto del QR'));
    await tester.pump();
    await tester.tap(find.text('Mejor escribo el código'));
    await tester.pumpAndSettle();
    pending.complete('/test/qr.png');
    await tester.pumpAndSettle();
    expect(camera.analyzedImages, isEmpty);
    expect(repo.codes, isEmpty);
    expect(find.byType(ConsultaInputScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets(
    'Salir durante el análisis libera la cámara sin consultar la foto tardía',
    (tester) async {
      camera.imageGate = Completer<BarcodeCapture?>();
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      await tester.tap(find.text('Elegir foto del QR'));
      await tester.pump();
      expect(camera.analyzedImages, hasLength(1));
      camera.detect('AB3K7X');
      await tester.pump();
      expect(repo.codes, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(camera.disposals, 0);
      camera.imageGate!.complete(photoCapture('AB3K7X'));
      await tester.pumpAndSettle();
      expect(camera.disposals, greaterThan(0));
      expect(repo.codes, isEmpty);
      expect(find.byType(ConsultaInputScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );

  testWidgets(
    'Un QR válido consulta una sola vez y detiene la cámara antes de la RPC',
    (tester) async {
      final pending = Completer<ConsultaLookupResult>();
      final repo = _QrRepository((_) {
        expect(camera.stops, greaterThan(0));
        return pending.future;
      });
      await pumpInput(tester, repo);
      await openScanner(tester);
      expect(camera.lastOptions!.formats, [BarcodeFormat.qrCode]);
      expect(camera.lastOptions!.returnImage, isFalse);
      camera.detect('ab-3k7x');
      camera.detect('AB3K7X');
      camera.detect('CD4P9Z');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 1));
      expect(repo.codes, ['AB3K7X']);
      expect(find.byType(ConsultaQrScreen), findsNothing);
      pending.complete(
        const ConsultaLookupResult(
          status: ConsultaStatus.recibido,
          code: 'AB3K7X',
          hospitalName: 'Hospital de la consulta QR',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConsultaStatusScreen), findsOneWidget);
      expect(find.text('Código AB3K7X'), findsOneWidget);
      expect(find.text('Hospital de la consulta QR'), findsOneWidget);
      expect(repo.codes, hasLength(1));
      expect(camera.disposals, greaterThan(0));
      await close(tester);
    },
  );

  for (final raw in ['https://ejemplo.test/AB3K7X', 'ABCDEFG', 'AB!K7X']) {
    testWidgets('QR ajeno al formato no consulta y permite leer otro: $raw', (
      tester,
    ) async {
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      camera.detect(raw);
      await tester.pumpAndSettle();
      expect(repo.codes, isEmpty);
      expect(find.textContaining('Este QR no contiene'), findsOneWidget);
      expect(find.byType(ConsultaQrScreen), findsOneWidget);
      camera.detect('CD4P9Z');
      await tester.pumpAndSettle();
      expect(repo.codes, ['CD4P9Z']);
      expect(find.text('Código CD4P9Z'), findsOneWidget);
      await close(tester);
    });
  }

  testWidgets('No utiliza códigos de barras distintos de QR', (tester) async {
    final repo = successfulRepository();
    await pumpInput(tester, repo);
    await openScanner(tester);
    camera.detect('AB3K7X', format: BarcodeFormat.code128);
    await tester.pumpAndSettle();
    expect(repo.codes, isEmpty);
    expect(find.byType(ConsultaQrScreen), findsOneWidget);
    await close(tester);
  });

  testWidgets('Un QR inexistente termina en A07 conservando el código', (
    tester,
  ) async {
    final repo = _QrRepository(
      (_) async => throw const PostgrestException(
        message: 'not_found',
        code: 'not_found',
      ),
    );
    await pumpInput(tester, repo);
    await openScanner(tester);
    camera.detect('AB3K7X');
    await tester.pumpAndSettle();
    expect(repo.codes, ['AB3K7X']);
    expect(find.text('El código no existe o ya venció'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'AB3K7X',
    );
    expect(find.byType(ConsultaStatusScreen), findsNothing);
    await close(tester);
  });

  for (final failure in [
    Exception('Sin conexión'),
    const ConsultaRateLimitException(),
  ]) {
    testWidgets(
      'Un fallo de consulta vuelve al ingreso conservando el QR: $failure',
      (tester) async {
        final repo = _QrRepository((_) async => throw failure);
        await pumpInput(tester, repo);
        await openScanner(tester);
        camera.detect('AB3K7X');
        await tester.pumpAndSettle();
        expect(repo.codes, ['AB3K7X']);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byType(ConsultaQrScreen), findsNothing);
        expect(find.byType(ConsultaStatusScreen), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'AB3K7X',
        );
        await close(tester);
      },
    );
  }

  testWidgets(
    'Permiso denegado permite reintentar y volver a escritura manual',
    (tester) async {
      camera.startError = const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await tester.enterText(find.byType(TextField), 'CD4P9Z');
      await openScanner(tester);
      expect(find.text('Permiso de cámara denegado'), findsOneWidget);
      expect(repo.codes, isEmpty);
      camera.startError = null;
      await tester.ensureVisible(find.text('Reintentar cámara'));
      await tester.tap(find.text('Reintentar cámara'));
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      expect(find.text('Permiso de cámara denegado'), findsNothing);
      await tester.tap(find.text('Mejor escribo el código'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'CD4P9Z',
      );
      expect(repo.codes, isEmpty);
      await close(tester);
    },
  );

  testWidgets(
    'Una cámara no disponible muestra un aviso y conserva la alternativa manual',
    (tester) async {
      camera.startError = const MobileScannerException(
        errorCode: MobileScannerErrorCode.unsupported,
      );
      await pumpInput(tester, successfulRepository());
      await openScanner(tester);
      expect(find.text('Cámara no disponible'), findsOneWidget);
      expect(
        find.text('Mejor escribo el código').hitTestable(),
        findsOneWidget,
      );
      await close(tester);
    },
  );

  testWidgets('La cámara se detiene en segundo plano y vuelve al regresar', (
    tester,
  ) async {
    await pumpInput(tester, successfulRepository());
    await openScanner(tester);
    expect(camera.starts, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(camera.stops, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    await close(tester);
    expect(camera.stops, greaterThanOrEqualTo(2));
  });

  testWidgets(
    'Salir durante el permiso libera también una cámara que termina de iniciar tarde',
    (tester) async {
      camera.startGate = Completer<void>();
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await openScanner(tester);
      await tester.tap(find.text('Mejor escribo el código'));
      await tester.pumpAndSettle();
      camera.startGate!.complete();
      await tester.pumpAndSettle();
      expect(camera.stops, greaterThan(0));
      expect(camera.disposals, greaterThan(0));
      expect(repo.codes, isEmpty);
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );

  testWidgets('Un regreso rápido espera que termine la detención de cámara', (
    tester,
  ) async {
    await pumpInput(tester, successfulRepository());
    await openScanner(tester);
    camera.stopGate = Completer<void>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(camera.starts, 1);
    camera.stopGate!.complete();
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    camera.stopGate = null;
    await close(tester);
  });

  testWidgets(
    'El permiso inicial no pierde el reinicio si la app vuelve mientras la cámara se detiene',
    (tester) async {
      camera.startGate = Completer<void>();
      camera.stopGate = Completer<void>();
      await pumpInput(tester, successfulRepository());
      await openScanner(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      camera.startGate!.complete();
      await tester.pump();
      expect(camera.stops, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      camera.stopGate!.complete();
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      camera.stopGate = null;
      await close(tester);
    },
  );

  testWidgets(
    'Regresar antes de una detección tardía no consulta ni cierra A04',
    (tester) async {
      final repo = successfulRepository();
      await pumpInput(tester, repo);
      await tester.enterText(find.byType(TextField), 'CD4P9Z');
      await openScanner(tester);
      await tester.binding.handlePopRoute();
      camera.detect('AB3K7X');
      await tester.pumpAndSettle();
      expect(repo.codes, isEmpty);
      expect(find.byType(ConsultaInputScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'CD4P9Z',
      );
      await close(tester);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 600),
  ]) {
    testWidgets('A05 mantiene el regreso manual con texto ampliado en $size', (
      tester,
    ) async {
      await pumpInput(tester, successfulRepository(), size: size, textScale: 2);
      await openScanner(tester);
      expect(find.text('Elegir foto del QR').hitTestable(), findsOneWidget);
      expect(find.text('Elegir foto del QR').hitTestable(), findsOneWidget);
      expect(
        find.text('Mejor escribo el código').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.text('Mejor escribo el código'));
      await tester.pumpAndSettle();
      expect(find.byType(ConsultaQrScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }

  testWidgets(
    'Windows conserva el ingreso manual sin intentar abrir una cámara no compatible',
    (tester) async {
      await pumpInput(tester, successfulRepository());
      await openScanner(tester);
      expect(camera.starts, 0);
      expect(find.text('Cámara no disponible'), findsOneWidget);
      expect(
        find.text('Mejor escribo el código').hitTestable(),
        findsOneWidget,
      );
      await close(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
