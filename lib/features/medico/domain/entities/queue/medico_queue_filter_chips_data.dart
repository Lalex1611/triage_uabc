import 'package:flutter/foundation.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';

@immutable
class MedicoQueueFilterChipsData {
  final MedicoQueueFilter selectedFilter;
  final ValueChanged<MedicoQueueFilter> onFilterSelected;

  const MedicoQueueFilterChipsData({
    required this.selectedFilter,
    required this.onFilterSelected,
  });
}
