import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// Pantalla con un botón que ejecuta [show] con su contexto
Future<void> _show(
  WidgetTester tester,
  void Function(BuildContext context) show,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => show(context),
            child: const Text('mostrar'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mostrar'));
  await tester.pumpAndSettle();
}

String _iconAsset(WidgetTester tester) => tester
    .widget<TriageIcon>(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(TriageIcon),
      ),
    )
    .asset;

void main() {
  testWidgets('flotante, fondo oscuro, ícono del tono y mensaje', (
    tester,
  ) async {
    await _show(
      tester,
      (c) =>
          showTriageToast(c, 'Paciente registrado', tone: TriageTone.success),
    );
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.behavior, SnackBarBehavior.floating);
    expect(bar.backgroundColor, TriageColors.inverse);
    expect(find.text('Paciente registrado'), findsOneWidget);
    expect(_iconAsset(tester), TriageIcons.checkCircle);
  });

  testWidgets('la acción se muestra y responde', (tester) async {
    var undone = 0;
    await _show(
      tester,
      (c) => showTriageToast(
        c,
        'Paciente eliminado',
        actionLabel: 'Deshacer',
        onAction: () => undone++,
      ),
    );
    await tester.tap(find.text('Deshacer'));
    expect(undone, 1);
  });

  testWidgets('showAppSnackBar usa el aviso breve: error → peligro', (
    tester,
  ) async {
    await _show(tester, (c) => showAppSnackBar(c, 'Falló', isError: true));
    expect(_iconAsset(tester), TriageIcons.reject);
  });

  testWidgets('showAppSnackBar sin error → informativo', (tester) async {
    await _show(tester, (c) => showAppSnackBar(c, 'Guardado'));
    expect(_iconAsset(tester), TriageIcons.info);
  });

  testWidgets('sin ScaffoldMessenger no falla', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            showTriageToast(context, 'Hola');
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('contraste sobre el fondo oscuro', () {
    expect(
      _contrast(TriageColors.textInverse, TriageColors.inverse),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(TriageColors.infoOnInverse, TriageColors.inverse),
      greaterThanOrEqualTo(4.5),
      reason: 'texto de la acción',
    );
    for (final tone in TriageTone.values) {
      expect(
        _contrast(tone.onInverse, TriageColors.inverse),
        greaterThanOrEqualTo(3),
        reason: tone.name,
      );
    }
  });
}
