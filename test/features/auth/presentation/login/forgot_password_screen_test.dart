import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/auth/presentation/login/forgot_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'));
    await font.load();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    double keyboardHeight = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 46, bottom: 24),
            viewInsets: EdgeInsets.only(bottom: keyboardHeight),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const ForgotPasswordScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('A03 queda fija y permite escribir sin enviar correos', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('Recupera tu acceso'), findsOneWidget);
    final scrollable = find
        .descendant(
          of: find.byType(ForgotPasswordScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      0,
    );
    await tester.enterText(find.byType(TextFormField), 'nombre@ejemplo.com');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pump();
    expect(
      find.text('La recuperación de contraseña aún no está disponible.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('A03 accesible a $size con texto al 200 % y teclado', (
      tester,
    ) async {
      await pumpScreen(tester, size: size, textScale: 2, keyboardHeight: 180);
      await tester.ensureVisible(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
      expect(find.text('Enviar enlace').hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.text('Volver a iniciar sesión'));
      await tester.pumpAndSettle();
      expect(
        find.text('Volver a iniciar sesión').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final useArrow in [true, false]) {
    testWidgets('regreso al acceso con ${useArrow ? 'flecha' : 'botón'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('Abrir A03'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir A03'));
      await tester.pumpAndSettle();
      if (useArrow) {
        await tester.tap(find.byTooltip('Regresar'));
      } else {
        await tester.ensureVisible(find.text('Volver a iniciar sesión'));
        await tester.tap(find.text('Volver a iniciar sesión'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Abrir A03'), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });
  }
}
