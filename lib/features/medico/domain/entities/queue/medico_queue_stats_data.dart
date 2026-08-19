import 'package:flutter/foundation.dart';

@immutable
class MedicoQueueStatsData {
  final int enCaminoCount;
  final int rojosCriticosCount;
  final int enColaCount;

  const MedicoQueueStatsData({
    required this.enCaminoCount,
    required this.rojosCriticosCount,
    required this.enColaCount,
  });
}
