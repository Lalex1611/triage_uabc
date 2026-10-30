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
