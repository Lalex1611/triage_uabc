import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  setUp(() {
    camera = installFakeQrCamera();
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
