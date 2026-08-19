import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class TriageColorGridData {
  final List<TriageCategory> categories;
  final Function(TriageCategory) onColorSelected;

  TriageColorGridData({
    required this.categories,
    required this.onColorSelected,
  });
}
