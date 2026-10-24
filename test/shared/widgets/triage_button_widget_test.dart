import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_button_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
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
