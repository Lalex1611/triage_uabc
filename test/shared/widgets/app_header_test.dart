import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';

Widget _wrap(Color color) => MaterialApp(
  home: Scaffold(
    appBar: AppHeader(
      type: HeaderType.incident,
      color: color,
      isConnected: true,
      hasNotifications: false,
      backLabel: 'Regresar',
      actionLabel: 'Editar',
      onBack: () {},
      onAction: () {},
    ),
  ),
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Future<void> _expectForeground(
  WidgetTester tester,
  Color background,
  Color expected,
) async {
  await tester.pumpWidget(_wrap(background));
  for (final label in ['Regresar', 'Editar']) {
    expect(tester.widget<Text>(find.text(label)).style!.color, expected);
  }
  expect(
    tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter,
    ColorFilter.mode(expected, BlendMode.srcIn),
  );
}

void main() {
  testWidgets('sobre la cabecera blanca del incidente usa negro', (
    tester,
  ) async {
    await _expectForeground(tester, Colors.white, Colors.black);
  });

  testWidgets('sobre el rojo del módulo usa blanco', (tester) async {
    await _expectForeground(tester, paramedicoHeaderColor(null), Colors.white);
  });

  testWidgets('el triage negro no queda negro sobre negro', (tester) async {
    await _expectForeground(
      tester,
      paramedicoHeaderColor(TriageCategory.negro),
      Colors.white,
    );
  });

  testWidgets('el triage amarillo usa negro', (tester) async {
    await _expectForeground(
      tester,
      paramedicoHeaderColor(TriageCategory.amarillo),
      Colors.black,
    );
  });

  testWidgets('todos los colores de triage se leen sobre su cabecera', (
    tester,
  ) async {
    for (final category in triageCategoriesForPatientInsert) {
      final background = paramedicoHeaderColor(category);
      await tester.pumpWidget(_wrap(background));
      final color = tester.widget<Text>(find.text('Regresar')).style!.color!;
      expect(
        _contrast(color, background),
        greaterThanOrEqualTo(3),
        reason: category.label,
      );
    }
  });
}
