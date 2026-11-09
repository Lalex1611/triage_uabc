import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/auth/presentation/login/login_screen.dart';
import 'package:sistema_triage/features/auth/presentation/login/widgets/auth_text_field.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'));
    await font.load();
  });

  Future<void> pumpLogin(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
    double keyboardHeight = 0,
    EdgeInsets safePadding = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboardHeight),
            padding: safePadding,
          ),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(390, 844), const Size(412, 915)]) {
    testWidgets('acceso fijo sin desplazamiento a $size', (tester) async {
      await pumpLogin(
        tester,
        size,
        safePadding: const EdgeInsets.only(top: 46, bottom: 24),
      );
      final page = find
          .descendant(
            of: find.byType(LoginScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      final position = tester.state<ScrollableState>(page).position;
      expect(position.maxScrollExtent, 0);
      final titleBefore = tester.getTopLeft(find.text('Inicia tu turno'));
      await tester.drag(find.text('Inicia tu turno'), const Offset(0, -160));
      await tester.pumpAndSettle();
      expect(position.pixels, 0);
      expect(tester.getTopLeft(find.text('Inicia tu turno')), titleBefore);
      expect(find.text('Entrar').hitTestable(), findsOneWidget);
      expect(
        find.text('Consultar a un paciente').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    testWidgets('acceso sin desbordes a $size y texto al 200 %', (
      tester,
    ) async {
      await pumpLogin(tester, size, textScale: 2);
      await tester.ensureVisible(find.text('Consultar a un paciente'));
      await tester.pumpAndSettle();
      expect(
        find.text('Consultar a un paciente').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.maxLength, 60);
      }
    });
  }

  testWidgets('con teclado se puede desplazar hasta Entrar', (tester) async {
    await pumpLogin(tester, const Size(320, 568), keyboardHeight: 280);
    await tester.ensureVisible(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conserva texto, límite y contraseña oculta al reconstruirse', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(390, 844));
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'usuario@ejemplo.com');
    await tester.enterText(fields.last, 'clave-de-prueba');
    expect(tester.widget<TextField>(fields.last).obscureText, isTrue);
    expect(
      tester.widget<TextField>(fields.last).controller!.text,
      'clave-de-prueba',
    );
    await tester.enterText(fields.first, List.filled(80, 'a').join());
    expect(tester.widget<TextField>(fields.first).controller!.text.length, 60);
    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(fields.last).controller!.text,
      'clave-de-prueba',
    );
  });

  testWidgets('consultar conserva la ruta de consulta externa', (tester) async {
    final router = GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(path: '/auth', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/consulta-externa',
          builder: (_, _) => const Scaffold(body: Text('Destino consulta')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Consultar a un paciente'));
    await tester.tap(find.text('Consultar a un paciente'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/consulta-externa');
    expect(find.text('Destino consulta'), findsOneWidget);
  });

  testWidgets('A02 presenta la validación existente sin enviar credenciales', (
    tester,
  ) async {
    // Configuración ficticia: la validación vacía retorna antes de usar el SDK.
    SupabaseEnv.applyRuntimeFallback(
      url: 'https://example.invalid',
      anonKey: 'test-placeholder',
    );
    await pumpLogin(tester, const Size(390, 844));
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Ingresa correo y contraseña.'), findsOneWidget);
    expect(
      tester
          .widgetList<AuthTextField>(find.byType(AuthTextField))
          .every((field) => field.hasError),
      isTrue,
    );
    final border =
        tester
                .widget<TextField>(find.byType(TextField).first)
                .decoration!
                .enabledBorder!
            as OutlineInputBorder;
    expect(border.borderSide.color, TriageColors.danger);
    expect(tester.takeException(), isNull);
    // Permite que el aviso breve complete su temporizador antes del desmontaje.
    await tester.pump(const Duration(seconds: 5));
  });
}
