import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/offline/offline_capture_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/offline/offline_connection_page.dart';

void main() {
  testWidgets('la foto reutiliza su carga al redibujar la captura', (
    tester,
  ) async {
    final loads = <Completer<Uint8List>>[];

    Future<void> pump({
      String id = 'primera-foto',
      int session = 1,
      bool synced = false,
    }) => tester.pumpWidget(
      MaterialApp(
        home: OfflineCapturePhoto(
          requestIdentity: (id, session),
          synced: synced,
          loadBytes: () {
            final next = Completer<Uint8List>();
            loads.add(next);
            return next.future;
          },
        ),
      ),
    );

    await pump();
    await pump();
    expect(loads, hasLength(1));

    await pump(synced: true);
    await pump(synced: true);
    expect(loads, hasLength(2));

    await pump(synced: true, id: 'segunda-foto');
    expect(loads, hasLength(3));

    await pump(synced: true, id: 'segunda-foto', session: 2);
    await pump(synced: true, id: 'segunda-foto', session: 2);
    expect(loads, hasLength(4));
    expect(find.text('Cargando foto…'), findsOneWidget);
  });

  testWidgets('A08 renders the mobile reference layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fonts = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'));
    await fonts.load();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          home: OfflineConnectionPage(
            canContinue: true,
            connected: false,
            onContinue: () {},
            onBack: () {},
            onRetry: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    const output = String.fromEnvironment('A08_PREVIEW_PATH');
    if (output.isNotEmpty) {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
  testWidgets(
    'A08 prevents duplicate retries and shows progress only during retry',
    (tester) async {
      final done = Completer<void>();
      var attempts = 0;
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          home: OfflineConnectionPage(
            canContinue: true,
            connected: false,
            onBack: () {},
            onContinue: () => continued = true,
            onRetry: () {
              attempts++;
              return done.future;
            },
          ),
        ),
      );
      expect(find.text('Reintentando…'), findsNothing);
      await tester.tap(find.text('Reintentar ahora'));
      await tester.pump();
      expect(find.text('Reintentando…'), findsNWidgets(2));
      await tester.tap(find.text('Reintentando…').last);
      expect(attempts, 1);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.text('Reintentando…'), findsNothing);
      await tester.tap(find.text('Seguir sin conexión'));
      expect(continued, true);
    },
  );
  testWidgets('unauthenticated A08 offers access instead of offline capture', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OfflineConnectionPage(
          canContinue: false,
          connected: false,
          onBack: () {},
          onRetry: () async {},
        ),
      ),
    );
    expect(find.text('Seguir sin conexión'), findsNothing);
    expect(find.text('Volver al acceso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('A08 fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: OfflineConnectionPage(
          canContinue: true,
          connected: false,
          onContinue: () {},
          onBack: () {},
          onRetry: () async {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Reintentar ahora'), findsOneWidget);
  });
}
