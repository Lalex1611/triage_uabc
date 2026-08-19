import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class DetailsTriageClassificationData {
  final TriageCategory selectedCategory;
  final bool canEdit;
  final bool isEditingMode; // Nuevo estado para indicar si ya picaron el lápiz
  final VoidCallback onEditTap;
  final Function(TriageCategory) onCategorySelected;

  const DetailsTriageClassificationData({
    required this.selectedCategory,
    required this.canEdit,
    required this.isEditingMode,
    required this.onEditTap,
    required this.onCategorySelected,
  });
}
