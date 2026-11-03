import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

Widget _wrap(Widget nav) =>
    MaterialApp(home: Scaffold(bottomNavigationBar: nav));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Color _textColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

void main() {
  testWidgets('el toque avisa el índice de la pestaña', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _wrap(ParamedicoNavbar(currentIndex: 0, onTap: (i) => tapped = i)),
    );
    await tester.tap(find.text('Mapa'));
    expect(tapped, 2);
  });

  testWidgets('colores por rol con contraste ≥ 4.5 sobre la superficie', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ParamedicoNavbar(currentIndex: 0, onTap: (_) {})),
    );
    expect(_textColor(tester, 'Home'), TriageColors.paramedicAccent);
    expect(_textColor(tester, 'Mapa'), TriageColors.textSecondary);

    await tester.pumpWidget(
      _wrap(MedicoNavbar(currentIndex: 0, onTap: (_) {})),
    );
    expect(_textColor(tester, 'Home'), TriageColors.hospitalAccent);
    expect(_textColor(tester, 'Registro'), TriageColors.textSecondary);

    for (final color in [
      TriageColors.paramedicAccent,
      TriageColors.hospitalAccent,
      TriageColors.textSecondary,
    ]) {
      expect(_contrast(color, TriageColors.surface), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('se anuncia como botón y marca la pestaña activa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ParamedicoNavbar(currentIndex: 2, onTap: (_) {})),
    );
    expect(
      tester.getSemantics(find.text('Mapa')),
      isSemantics(
        label: 'Mapa',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Home')),
      isSemantics(label: 'Home', isButton: true, isSelected: false),
    );
  });

  testWidgets('pestañas de igual ancho y con la zona táctil mínima', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ParamedicoNavbar(currentIndex: 0, onTap: (_) {})),
    );
    final sizes = tester
        .widgetList(find.byType(InkWell))
        .map((w) => tester.getSize(find.byWidget(w)));
    expect(sizes, hasLength(4));
    for (final size in sizes) {
      expect(size.width, sizes.first.width);
      expect(size.height, greaterThanOrEqualTo(TriageSizes.touchTarget));
    }
  });

  testWidgets('con texto al 200 % en pantalla angosta no se desborda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
        child: _wrap(ParamedicoNavbar(currentIndex: 1, onTap: (_) {})),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Incidente'), findsOneWidget);
  });
}
