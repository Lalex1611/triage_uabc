import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class PatientAppBarData {
  /* / Categoría START elegida; null = AppBar rojo paramédico. */
  final TriageCategory? triageCategory;

  /* / Callback para el botón "← Regresar a Home". */
  final VoidCallback onBackTap;

  /* / Callback para el botón "Cerrar Incidente". */
  final VoidCallback onCloseIncidentTap;

  const PatientAppBarData({
    required this.triageCategory,
    required this.onBackTap,
    required this.onCloseIncidentTap,
  });
}
