import 'package:flutter/foundation.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';

@immutable
class MedicoRegisterTriageData {
  final MedicoTriageCategory? selectedCategory;
  final ValueChanged<MedicoTriageCategory> onCategorySelected;

  // / Si es false, los cuadros de color están bloqueados
  final bool isEditingEnabled;

  // / Texto del título de triage hospitalario
  final String title;

  // / Si se provee, se muestra un lápiz a la derecha del título para abrir
  final VoidCallback? onEditTap;

  const MedicoRegisterTriageData({
    required this.selectedCategory,
    required this.onCategorySelected,
    this.isEditingEnabled = true,
    this.title = 'Seleccione el triage hospitalario',
    this.onEditTap,
  });
}
