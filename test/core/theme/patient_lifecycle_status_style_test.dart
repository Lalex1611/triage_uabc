import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/theme/patient_lifecycle_status_style.dart';
import 'package:sistema_triage/shared/domain/patient_lifecycle_status.dart';

/// Relación de contraste WCAG 2.x
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('etiquetas únicas y no vacías', () {
    final labels = PatientLifecycleStatus.values.map((s) => s.label).toSet();
    expect(labels.length, PatientLifecycleStatus.values.length);
    expect(labels.every((l) => l.isNotEmpty), isTrue);
  });

  test(
    'texto de la insignia ≥ 4.5:1 sobre su fondo (WCAG AA texto pequeño)',
    () {
      for (final status in PatientLifecycleStatus.values) {
        expect(
          _contrast(status.textColor, status.background),
          greaterThanOrEqualTo(4.5),
          reason: status.name,
        );
      }
    },
  );
}
