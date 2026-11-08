import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/medico/presentation/navigation/medico_navbar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

const _paramedicoTabs = ['Mapa', 'Incidentes', 'Guía START', 'Perfil'];

Widget _wrap(Widget nav) =>
    MaterialApp(home: Scaffold(bottomNavigationBar: nav));

Widget _paramedico({
  int currentIndex = ParamedicoNavbar.mapTab,
  ValueChanged<int>? onTap,
  VoidCallback? onCreateIncident,
}) => ParamedicoNavbar(
  currentIndex: currentIndex,
  onTap: onTap ?? (_) {},
  onCreateIncident: onCreateIncident ?? () {},
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Color _textColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

Size _tabSize(WidgetTester tester, String label) => tester.getSize(
  find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
);

final _createIncident = find.bySemanticsLabel('Crear incidente');

void main() {
  testWidgets('el toque avisa el índice de la pestaña sin contar el "+"', (
    tester,
  ) async {
    final tapped = <int>[];
    await tester.pumpWidget(_wrap(_paramedico(onTap: tapped.add)));
    for (final label in _paramedicoTabs) {
      await tester.tap(find.text(label));
    }
    expect(tapped, [
      ParamedicoNavbar.mapTab,
      ParamedicoNavbar.incidentsTab,
      ParamedicoNavbar.guideTab,
      ParamedicoNavbar.profileTab,
    ]);
  });

  testWidgets('colores por rol con contraste ≥ 4.5 sobre la superficie', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_paramedico()));
    expect(_textColor(tester, 'Mapa'), TriageColors.paramedicAccent);
    expect(_textColor(tester, 'Incidentes'), TriageColors.textSecondary);

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
      _wrap(_paramedico(currentIndex: ParamedicoNavbar.guideTab)),
    );
    expect(
      tester.getSemantics(find.text('Guía START')),
      isSemantics(
        label: 'Guía START',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Mapa')),
      isSemantics(label: 'Mapa', isButton: true, isSelected: false),
    );
  });

  testWidgets('con un índice fuera de rango ninguna pestaña queda activa', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_paramedico(currentIndex: -1)));
    for (final label in _paramedicoTabs) {
      expect(_textColor(tester, label), TriageColors.textSecondary);
      expect(
        tester.getSemantics(find.text(label)),
        isSemantics(label: label, isButton: true, isSelected: false),
      );
    }
  });

  testWidgets('pestañas de igual ancho y con la zona táctil mínima', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_paramedico()));
    final first = _tabSize(tester, _paramedicoTabs.first);
    for (final label in _paramedicoTabs) {
      final size = _tabSize(tester, label);
      expect(size.width, first.width);
      expect(size.height, greaterThanOrEqualTo(TriageSizes.touchTarget));
    }
  });

  testWidgets('el "+" crea un incidente y no cambia de pestaña', (
    tester,
  ) async {
    final tapped = <int>[];
    var created = 0;
    await tester.pumpWidget(
      _wrap(_paramedico(onTap: tapped.add, onCreateIncident: () => created++)),
    );
    await tester.tap(_createIncident);
    expect(created, 1);
    expect(tapped, isEmpty);
  });

  testWidgets('el "+" se anuncia como botón y tiene zona táctil mínima', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_paramedico()));
    expect(
      tester.getSemantics(_createIncident),
      isSemantics(label: 'Crear incidente', isButton: true, hasTapAction: true),
    );
    final size = tester.getSize(_createIncident);
    expect(size.width, greaterThanOrEqualTo(TriageSizes.touchTarget));
    expect(size.height, greaterThanOrEqualTo(TriageSizes.touchTarget));
    expect(
      _contrast(TriageColors.textInverse, TriageColors.paramedicAccent),
      greaterThanOrEqualTo(3),
    );
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
        child: _wrap(_paramedico(currentIndex: ParamedicoNavbar.incidentsTab)),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final label in _paramedicoTabs) {
      expect(find.text(label), findsOneWidget);
    }
    expect(_createIncident, findsOneWidget);
  });
}
