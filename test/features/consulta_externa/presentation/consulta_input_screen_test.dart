import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_input_screen.dart';

void main() {
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
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ConsultaInputScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Normaliza seis caracteres sin consultar y rechaza entradas largas',
    (tester) async {
      await pumpScreen(tester);
      final field = find.byType(TextField);
      await tester.enterText(field, 'ab-3 k7x');
      expect(tester.widget<TextField>(field).controller!.text, 'AB3K7X');
      for (var index = 0; index < 6; index++) {
        expect(
          find.byKey(ValueKey('consulta-code-cell-$index')),
          findsOneWidget,
        );
      }
      await tester.enterText(field, 'ABCDEFG');
      expect(tester.widget<TextField>(field).controller!.text, 'AB3K7X');
      expect(find.text('Consultar estado'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 600),
  ]) {
    testWidgets('Acciones accesibles sin desbordamiento a $size', (
      tester,
    ) async {
      await pumpScreen(tester, size: size);
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

  testWidgets('Permite desplazarse con teclado y texto ampliado', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      size: const Size(320, 568),
      textScale: 2,
      keyboardHeight: 260,
    );
    await tester.enterText(find.byType(TextField), 'AB3K7X');
    await tester.ensureVisible(find.text('Consultar estado'));
    await tester.pumpAndSettle();
    expect(find.text('Consultar estado').hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.text('¿Cómo funciona?'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo funciona?').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Regresar conserva el pop de la ruta anterior', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Anterior')),
        ),
        GoRoute(
          path: '/consulta-externa',
          builder: (context, state) => const ConsultaInputScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: appTheme, routerConfig: router),
    );
    router.push('/consulta-externa');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Regresar'));
    await tester.pumpAndSettle();
    expect(find.text('Anterior'), findsOneWidget);
    expect(find.byType(ConsultaInputScreen), findsNothing);
  });
}
