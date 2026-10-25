import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';

/// Relación de contraste WCAG 2.x
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('cada nivel usa su token de Figma', () {
    expect(TriageLevel.red.color, TriageColors.triageRed);
    expect(TriageLevel.orange.color, TriageColors.triageOrange);
    expect(TriageLevel.yellow.color, TriageColors.triageYellow);
    expect(TriageLevel.green.color, TriageColors.triageGreen);
    expect(TriageLevel.blue.color, TriageColors.triageBlue);
    expect(TriageLevel.black.color, TriageColors.triageBlack);
  });

  test('fondo tenue: definido salvo naranja y azul', () {
    for (final level in TriageLevel.values) {
      final sinFondo = level == TriageLevel.orange || level == TriageLevel.blue;
      expect(level.background == null, sinFondo, reason: level.name);
    }
  });

  test('texto oscuro sobre amarillo y naranja, blanco en el resto', () {
    for (final level in TriageLevel.values) {
      expect(
        level.onColor,
        level == TriageLevel.yellow || level == TriageLevel.orange
            ? TriageColors.textPrimary
            : TriageColors.textInverse,
        reason: level.name,
      );
    }
  });

  test('etiquetas únicas', () {
    final labels = TriageLevel.values.map((l) => l.label).toSet();
    expect(labels.length, TriageLevel.values.length);
  });

  test('contraste texto/fondo ≥ 3:1 (WCAG AA texto grande)', () {
    for (final level in TriageLevel.values) {
      final ratio = _contrast(level.onColor, level.color);
      expect(ratio, greaterThanOrEqualTo(3), reason: level.name);
    }
  });
}
