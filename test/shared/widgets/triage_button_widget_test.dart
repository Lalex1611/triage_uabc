import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_button_widget.dart';

Widget _wrap(Widget child, {TriageRoleTheme? role}) => MaterialApp(
  theme: ThemeData(extensions: [?role]),
  home: Scaffold(body: Center(child: child)),
);

Color? _background(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(TriageButton),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('primary toma el color del rol: hospital → azul', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TriageButton(label: 'Aceptar', onPressed: () {}),
        role: TriageRoleTheme.hospital,
      ),
    );
    expect(_background(tester), TriageColors.hospitalAccent);
  });

  testWidgets('primary sin tema de rol → rojo de campo', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageButton(label: 'Entrar', onPressed: () {})),
    );
    expect(_background(tester), TriageColors.paramedicAccent);
  });

  testWidgets('habilitado: llama onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(TriageButton(label: 'Entrar', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Entrar'));
    expect(taps, 1);
  });

  testWidgets('deshabilitado: opacidad 40 % y sin acción', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageButton(label: 'Entrar', onPressed: null)),
    );
    final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, 0.4);
    await tester.tap(find.text('Entrar'), warnIfMissed: false);
  });

  testWidgets('cargando: spinner, conserva el ancho y no llama onPressed', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(TriageButton(label: 'Guardar paciente', onPressed: () => taps++)),
    );
    final idleWidth = tester.getSize(find.byType(TriageButton)).width;

    await tester.pumpWidget(
      _wrap(
        TriageButton(
          label: 'Guardar paciente',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(TriageButton)).width, idleWidth);
    await tester.tap(find.byType(TriageButton));
    expect(taps, 0);
  });

  testWidgets('altura mínima por tamaño: grande 54, mediano 44', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TriageButton(key: const Key('l'), label: 'A', onPressed: () {}),
            TriageButton(
              key: const Key('m'),
              label: 'A',
              size: TriageButtonSize.medium,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('l'))).height, 54);
    expect(tester.getSize(find.byKey(const Key('m'))).height, 44);
  });
}
