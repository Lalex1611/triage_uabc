import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/data/repositories/consulta_repository.dart';
import 'package:sistema_triage/features/consulta_externa/domain/constants/consulta_status.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_rate_limit_exception.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_status_screen.dart';

class _TestRepository extends ConsultaRepository {
  final Future<ConsultaLookupResult> Function(int) respond;
  final codes = <String>[];

  _TestRepository(this.respond);

  @override
  Future<ConsultaLookupResult> lookupByCode(String code) {
    codes.add(code);
    return respond(codes.length);
  }
}

void main() {
  const initial = ConsultaLookupResult(
    code: 'AB3K7X',
    status: ConsultaStatus.trasladando,
    hospitalName: 'Hospital anterior',
  );
  final updated = ConsultaLookupResult(
    code: 'AB3K7X',
    status: ConsultaStatus.recibido,
    hospitalName: 'Hospital actualizado',
    hospitalAddress: 'Dirección actualizada',
    hospitalPhone: '664-123-4567',
    statusChangedAt: DateTime.now().subtract(const Duration(minutes: 2)),
  );

  setUp(() {
    SupabaseEnv.applyRuntimeFallback(
      url: 'https://consulta.example.test',
      anonKey: 'test-only-key',
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    _TestRepository repository, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ConsultaStatusScreen(result: initial, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> closeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('Consulta cada minuto y reemplaza estado, hospital y fecha', (
    tester,
  ) async {
    final repo = _TestRepository((_) async => updated);
    await pumpScreen(tester, repo);
    expect(repo.codes, isEmpty);
    await tester.pump(const Duration(seconds: 59));
    expect(repo.codes, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repo.codes, ['AB3K7X']);
    expect(find.text('Recibido en hospital'), findsOneWidget);
    expect(find.text('Hospital actualizado'), findsOneWidget);
    expect(find.text('Dirección actualizada'), findsOneWidget);
    expect(find.text('664-123-4567'), findsOneWidget);
    expect(find.textContaining('Actualizado hace'), findsOneWidget);
    expect(find.text('Hospital anterior'), findsNothing);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(repo.codes, hasLength(2));
    await closeScreen(tester);
  });

  testWidgets(
    'Actualiza manualmente sin consultas simultáneas ni pulsaciones repetidas',
    (tester) async {
      final pending = Completer<ConsultaLookupResult>();
      final repo = _TestRepository(
        (call) => call == 1 ? pending.future : Future.value(updated),
      );
      await pumpScreen(tester, repo);
      await tester.tap(find.byTooltip('Actualizar estado'));
      await tester.pump();
      expect(repo.codes, hasLength(1));
      await tester.tap(find.byType(IconButton).last);
      await tester.pump(const Duration(minutes: 2));
      expect(repo.codes, hasLength(1));
      pending.complete(updated);
      await tester.pumpAndSettle();
      expect(find.text('Recibido en hospital'), findsOneWidget);
      await tester.pump(const Duration(seconds: 34));
      expect(
        tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byTooltip('Actualizar estado'));
      await tester.pumpAndSettle();
      expect(repo.codes, hasLength(2));
      await closeScreen(tester);
    },
  );

  testWidgets(
    'Un fallo conserva los datos, muestra un aviso y permite recuperarse',
    (tester) async {
      final repo = _TestRepository((call) async {
        if (call == 1) throw Exception('Fallo de conexión');
        return updated;
      });
      await pumpScreen(tester, repo);
      await tester.tap(find.byTooltip('Actualizar estado'));
      await tester.pumpAndSettle();
      expect(find.text('Hospital anterior'), findsOneWidget);
      expect(
        find.textContaining('Se muestra la última información consultada'),
        findsOneWidget,
      );
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Hospital actualizado'), findsOneWidget);
      expect(
        find.textContaining('Se muestra la última información consultada'),
        findsNothing,
      );
      await closeScreen(tester);
    },
  );

  testWidgets(
    'Código vencido oculta el resultado anterior y detiene las consultas',
    (tester) async {
      final repo = _TestRepository(
        (_) async => throw const PostgrestException(
          message: 'not_found',
          code: 'not_found',
        ),
      );
      await pumpScreen(tester, repo);
      await tester.tap(find.byTooltip('Actualizar estado'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('El código no existe o ya venció'),
        findsOneWidget,
      );
      expect(find.text('Consultar otro código'), findsOneWidget);
      expect(find.text('Hospital anterior'), findsNothing);
      expect(find.text('En camino al hospital'), findsNothing);
      await tester.pump(const Duration(minutes: 6));
      expect(repo.codes, hasLength(1));
      await closeScreen(tester);
    },
  );

  testWidgets(
    'El límite del servidor pausa cinco minutos y se recupera tras volver a la app',
    (tester) async {
      final repo = _TestRepository((call) async {
        if (call == 1) throw const ConsultaRateLimitException();
        return updated;
      });
      await pumpScreen(tester, repo);
      await tester.tap(find.byTooltip('Actualizar estado'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Espera cinco minutos'), findsOneWidget);
      expect(find.text('Hospital anterior'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(minutes: 3, seconds: 59));
      expect(repo.codes, hasLength(1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(repo.codes, hasLength(2));
      expect(find.text('Hospital actualizado'), findsOneWidget);
      await closeScreen(tester);
    },
  );

  testWidgets('No consulta en segundo plano ni después de cerrar A06', (
    tester,
  ) async {
    final repo = _TestRepository((_) async => updated);
    await pumpScreen(tester, repo);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 3));
    expect(repo.codes, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.codes, hasLength(1));
    await closeScreen(tester);
    await tester.pump(const Duration(minutes: 3));
    expect(repo.codes, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Una respuesta que llega después de salir no modifica la pantalla',
    (tester) async {
      final pending = Completer<ConsultaLookupResult>();
      final repo = _TestRepository((_) => pending.future);
      await pumpScreen(tester, repo);
      await tester.tap(find.byTooltip('Actualizar estado'));
      await tester.pump();
      await closeScreen(tester);
      pending.complete(updated);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 568), const Size(800, 600)]) {
    testWidgets(
      'Actualizar y el aviso siguen accesibles con texto ampliado en $size',
      (tester) async {
        final repo = _TestRepository(
          (_) async => throw Exception('Sin conexión'),
        );
        await pumpScreen(tester, repo, size: size, textScale: 2);
        expect(
          find.byTooltip('Actualizar estado').hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Actualizar estado'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Se muestra la última información consultada'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Esta consulta es limitada'));
        await tester.pumpAndSettle();
        expect(
          find.text('Esta consulta es limitada').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await closeScreen(tester);
      },
    );
  }

  testWidgets(
    'Consultar otro código vuelve a la entrada cuando el código vence',
    (tester) async {
      final repo = _TestRepository(
        (_) async => throw const PostgrestException(message: 'not_found'),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          initialRoute: '/estado',
          routes: {
            '/': (_) => const Scaffold(body: Text('Entrada por código')),
            '/estado': (_) =>
                ConsultaStatusScreen(result: initial, repository: repo),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Actualizar estado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consultar otro código'));
      await tester.pumpAndSettle();
      expect(find.text('Entrada por código'), findsOneWidget);
      expect(find.byType(ConsultaStatusScreen), findsNothing);
      await closeScreen(tester);
    },
  );
}
