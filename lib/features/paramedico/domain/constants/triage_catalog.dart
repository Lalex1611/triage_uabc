import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';

enum TriageCategory {
  todos('TODOS', Colors.transparent),
  rojo('ROJO', AppColors.triagePre_rojo),
  naranja('NARANJA', Color(0xFFFF9800)),
  amarillo('AMARILLO', AppColors.triagePre_amarillo),
  verde('VERDE', AppColors.triagePre_verde),
  azul('AZUL', Color(0xFF2196F3)),
  negro('NEGRO', AppColors.triagePre_negro);

  final String label;
  final Color color;

  const TriageCategory(this.label, this.color);
}

/// Valores para columna `patients.triage_color` / enum PostgreSQL (sin `todos`)
extension TriageCategorySql on TriageCategory {
  String get sqlValue => name;
}
