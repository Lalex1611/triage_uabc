import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget child, {double width = 400}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: width,
      child: Align(child: child),
    ),
  ),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(TriageStatusBadge),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

void main() {
  testWidgets('patient: etiqueta en mayúsculas y colores del estado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TriageStatusBadge.patient(PatientLifecycleStatus.received)),
    );
    expect(find.text('RECIBIDO'), findsOneWidget);
    expect(
      _decoration(tester).color,
      PatientLifecycleStatus.received.background,
    );
    final text = tester.widget<Text>(find.text('RECIBIDO'));
    expect(text.style!.color, PatientLifecycleStatus.received.textColor);
  });

  testWidgets('rejected: estado derivado con colores de peligro', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const TriageStatusBadge.rejected()));
    expect(find.text('RECHAZADO'), findsOneWidget);
    expect(_decoration(tester).color, TriageColors.dangerBackground);
  });

  for (final (label, badge, background) in const [
    ('REGISTRADO', TriageStatusBadge.registered(), TriageColors.sunken),
    (
      'DEFUNCIÓN',
      TriageStatusBadge.deceased(),
      TriageColors.triageBlackBackground,
    ),
    ('ACTIVO', TriageStatusBadge.active(), TriageColors.paramedicSoft),
    ('CERRADO', TriageStatusBadge.closed(), TriageColors.sunken),
  ]) {
    testWidgets('atajo $label: etiqueta, fondo y contraste', (tester) async {
      await tester.pumpWidget(_wrap(badge));
      expect(find.text(label), findsOneWidget);
      expect(_decoration(tester).color, background);
      final text = tester.widget<Text>(find.text(label)).style!.color!;
      final la = text.computeLuminance(), lb = background.computeLuminance();
      expect(
        (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  testWidgets('cerrado: punto y texto legibles sobre gris', (tester) async {
    await tester.pumpWidget(_wrap(const TriageStatusBadge.closed()));
    double contrast(Color a) {
      final la = a.computeLuminance();
      final lb = TriageColors.sunken.computeLuminance();
      return (la > lb ? la + 0.05 : lb + 0.05) /
          (la > lb ? lb + 0.05 : la + 0.05);
    }

    final dot =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(TriageStatusBadge),
                        matching: find.byType(Container),
                      )
                      .last,
                )
                .decoration!
            as BoxDecoration;
    expect(contrast(dot.color!), greaterThanOrEqualTo(3));
    expect(
      contrast(tester.widget<Text>(find.text('CERRADO')).style!.color!),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('altura mínima 26 y se ajusta al contenido', (tester) async {
    await tester.pumpWidget(
      _wrap(TriageStatusBadge.patient(PatientLifecycleStatus.waiting)),
    );
    final size = tester.getSize(find.byType(TriageStatusBadge));
    expect(size.height, 26);
    expect(size.width, lessThan(400));
  });

  testWidgets('etiqueta larga en espacio angosto: se corta sin desbordar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TriageStatusBadge(
          label: 'Un estado con una etiqueta demasiado larga',
          dotColor: TriageColors.info,
          textColor: TriageColors.infoText,
          background: TriageColors.infoBackground,
        ),
        width: 120,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TriageStatusBadge)).width, 120);
  });
}
