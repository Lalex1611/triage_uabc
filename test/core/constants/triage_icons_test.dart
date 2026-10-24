import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';

void main() {
  test('cada ícono de TriageIcons existe y es un SVG', () {
    expect(
      TriageIcons.all.toSet().length,
      TriageIcons.all.length,
      reason: 'rutas duplicadas',
    );
    for (final path in TriageIcons.all) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(
        file.readAsStringSync().trimLeft().startsWith('<svg'),
        isTrue,
        reason: path,
      );
    }
  });
}
