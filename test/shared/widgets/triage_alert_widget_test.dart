import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double width = 360, double textScale = 1}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Center(
        child: SizedBox(width: width, child: child),
      ),
    );

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  testWidgets('título, explicación e ícono del tono', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TriageAlert(
          tone: TriageTone.warning,
          title: 'Sin conexión',
          message: 'Se enviará al recuperar la señal.',
        ),
      ),
    );
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Se enviará al recuperar la señal.'), findsOneWidget);
    expect(
      tester.widget<TriageIcon>(find.byType(TriageIcon)).asset,
      TriageIcons.alert,
    );
  });

  testWidgets('sin explicación solo muestra el título', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageAlert(tone: TriageTone.info, title: 'Listo')),
    );
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('se anuncia solo al aparecer', (tester) async {
    await tester.pumpWidget(
      _wrap(const TriageAlert(tone: TriageTone.danger, title: 'Error')),
    );
    expect(
      tester.getSemantics(find.text('Error')),
      isSemantics(label: 'Error', isLiveRegion: true),
    );
  });

  test('cada tono: título ≥ 4.5 y explicación ≥ 4.5 sobre su fondo', () {
    for (final tone in TriageTone.values) {
      expect(
        _contrast(tone.color, tone.background),
        greaterThanOrEqualTo(4.5),
        reason: tone.name,
      );
      expect(
        _contrast(TriageColors.textSecondary, tone.background),
        greaterThanOrEqualTo(4.5),
        reason: tone.name,
      );
    }
  });

  testWidgets('con texto al 200 % en 320 crece sin desbordarse', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TriageAlert(
          tone: TriageTone.success,
          title: 'Traslado aceptado por el hospital',
          message: 'El hospital espera al paciente en urgencias.',
        ),
        width: 320,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
