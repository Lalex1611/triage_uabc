import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Archivos del sistema de diseño que el barrel debe exportar
List<String> _designSystemFiles() {
  final candidates = [
    ...Directory('lib/shared/widgets').listSync().whereType<File>().where(
      (f) => RegExp(r'triage_\w+_widget\.dart$').hasMatch(f.path),
    ),
    ...Directory('lib/shared/domain').listSync().whereType<File>(),
    ...Directory('lib/core/theme').listSync().whereType<File>().where(
      (f) => !f.path.endsWith('app_theme.dart'),
    ),
    File('lib/core/constants/triage_icons.dart'),
  ];
  return candidates
      .map((f) => f.path.replaceAll(r'\', '/').replaceFirst('lib/', ''))
      .toList();
}

void main() {
  test('triage_ui.dart exporta todos los componentes, tokens y dominio', () {
    final barrel = File('lib/shared/widgets/triage_ui.dart').readAsStringSync();
    for (final path in _designSystemFiles()) {
      expect(
        barrel.contains("export 'package:sistema_triage/$path';"),
        isTrue,
        reason: 'Falta exportar $path en triage_ui.dart',
      );
    }
  });

  testWidgets('un solo import alcanza tokens, tema, dominio y componentes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [TriageRoleTheme.hospital]),
        home: Column(
          children: [
            TriageButton(label: 'Aceptar', onPressed: () {}),
            TriageIcon(TriageIcons.bell, color: TriageLevel.red.color),
            Text(
              PatientLifecycleStatus.fromDb('recibido')!.label,
              style: TriageTextStyles.labelSmall,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Recibido'), findsOneWidget);
  });
}
