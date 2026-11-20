import 'package:flutter/foundation.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_sorting_options.dart';

@immutable
class MedicoQueueSectionHeaderData {
  final int total;
  final MedicoPatientSortOption currentSort;
  final ValueChanged<MedicoPatientSortOption> onSortTap;

  const MedicoQueueSectionHeaderData({
    required this.total,
    required this.currentSort,
    required this.onSortTap,
  });
}
