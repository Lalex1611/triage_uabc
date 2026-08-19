import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class PatientTriageClassificationData {
  /* / Categoría de triage actualmente seleccionada. Puede ser null si no se ha elegido aún. */
  final TriageCategory? selectedCategory;

  /* / Callback cuando el usuario selecciona un color de la grilla START. */
  final ValueChanged<TriageCategory> onCategorySelected;

  /* / Opcional: abre la pantalla negra START TRIAGE (asignación rápida + protocolo guiado). */
  final VoidCallback? onStartTriageTap;

  /// Título de la sección (p. ej. «Clasificación START» en detalle de paciente)
  final String sectionTitle;

  /// Si true, los colores no seleccionados se muestran al 50 % de opacidad
  final bool dimUnselectedColors;

  const PatientTriageClassificationData({
    required this.onCategorySelected,
    this.onStartTriageTap,
    this.selectedCategory,
    this.sectionTitle = 'Seleccione la clasificación START',
    this.dimUnselectedColors = false,
  });
}
