import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_input_screen.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_status_screen.dart';

void main() {
  const errorTitle = 'El código no existe o ya venció';

  setUp(() {
    SupabaseEnv.applyRuntimeFallback(
      url: 'https://consulta.example.test',
      anonKey: 'test-only-key',
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    double keyboardHeight = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/consulta-externa',
      routes: [
        GoRoute(
          path: '/consulta-externa',
          builder: (_, state) => const ConsultaInputScreen(),
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

  Future<void> submit(
    WidgetTester tester,
    MockClient client, {
    String label = 'Consultar estado',
  }) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => http.runWithClient(() async {
        await tester.tap(find.text(label));
        await Future<void>.delayed(Duration.zero);
      }, () => client),
    );
    await tester.pumpAndSettle();
  }

  for (final error in [
    {'message': 'not_found', 'code': '404'},
    {'message': 'Código expirado', 'code': 'P0001'},
  ]) {
    testWidgets('A07 presenta el error de servidor ${error['code']}', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'ab-3k7x');
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.method, 'POST');
        expect(request.url.path, '/rest/v1/rpc/get_patient_status_by_code');
        expect(jsonDecode(request.body), {'p_code': 'AB3K7X'});
        return http.Response(jsonEncode(error), 400);
      });
      await submit(tester, client);
      expect(requests, 1);
      expect(find.text(errorTitle), findsOneWidget);
      expect(find.text('Intentar de nuevo'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'AB3K7X',
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(ConsultaStatusScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final error in ['not_found', 'invalid_code']) {
    testWidgets('HTTP 200 con $error muestra A07 y conserva el código', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'AB3K7X');
      await submit(
        tester,
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'found': false, 'error': error}), 200),
        ),
      );
      expect(find.text(errorTitle), findsOneWidget);
      expect(find.text('Intentar de nuevo'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'AB3K7X',
      );
      expect(find.byType(ConsultaStatusScreen), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final failure in [
    (body: '{"found":false,"error":"rate_limited"}', message: 'cinco minutos'),
    (body: '{"found":true}', message: 'forma inesperada'),
  ]) {
    testWidgets('El fallo ${failure.body} no abre la pantalla de estado', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'AB3K7X');
      await submit(
        tester,
        MockClient((_) async => http.Response(failure.body, 200)),
      );
      expect(find.byType(ConsultaStatusScreen), findsNothing);
      expect(find.text(errorTitle), findsNothing);
      expect(find.textContaining(failure.message), findsOneWidget);
      expect(find.text('Consultar estado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Reintentar consulta el código editado y navega con los datos de la respuesta',
    (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'AB3K7X');
      final codes = <String>[];
      final client = MockClient((request) async {
        codes.add((jsonDecode(request.body) as Map)['p_code'] as String);
        if (codes.length == 1) {
          return http.Response('{"found":false,"error":"not_found"}', 200);
        }
        return http.Response(
          jsonEncode({
            'found': true,
            'patient_status': 'recibido',
            'hospital_name': 'Hospital simulado de la respuesta',
          }),
          200,
        );
      });
      await submit(tester, client);
      await tester.enterText(find.byType(TextField), 'cd-4p9z');
      await submit(tester, client, label: 'Intentar de nuevo');
      expect(codes, ['AB3K7X', 'CD4P9Z']);
      expect(find.byType(ConsultaStatusScreen), findsOneWidget);
      expect(find.text('Recibido en hospital'), findsOneWidget);
      expect(find.text('Hospital simulado de la respuesta'), findsOneWidget);
      expect(find.text(errorTitle), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Un fallo del servicio conserva el aviso y no se presenta como código inválido',
    (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'AB3K7X');
      await submit(tester, MockClient((_) async => http.Response('{}', 503)));
      expect(find.text(errorTitle), findsNothing);
      expect(
        find.textContaining('No pudimos procesar la solicitud'),
        findsOneWidget,
      );
      expect(find.text('Consultar estado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Código incompleto conserva la validación local sin llamar al servidor',
    (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'AB');
      var requests = 0;
      await submit(
        tester,
        MockClient((_) async {
          requests++;
          return http.Response('{}', 400);
        }),
      );
      expect(requests, 0);
      expect(find.text('Ingresa el código completo.'), findsOneWidget);
      expect(find.text(errorTitle), findsNothing);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 600),
  ]) {
    testWidgets('A07 permite reintentar con texto ampliado y teclado a $size', (
      tester,
    ) async {
      await pumpScreen(tester, size: size, textScale: 2, keyboardHeight: 180);
      await tester.enterText(find.byType(TextField), 'AB3K7X');
      await submit(
        tester,
        MockClient(
          (_) async =>
              http.Response('{"message":"not_found","code":"P0001"}', 400),
        ),
      );
      expect(find.text(errorTitle), findsOneWidget);
      await tester.ensureVisible(find.text('Intentar de nuevo'));
      await tester.pumpAndSettle();
      expect(find.text('Intentar de nuevo').hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.text('Escanear código QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escanear código QR'));
      await tester.pumpAndSettle();
      expect(
        find.text('Escaneo QR disponible en una futura versión.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
