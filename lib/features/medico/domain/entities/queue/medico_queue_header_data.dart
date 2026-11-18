import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Conteo de pacientes por nivel para las fichas del encabezado de la Sala
@immutable
class MedicoQueueLevelCount {
  final Color color;
  final int count;

  const MedicoQueueLevelCount({required this.color, required this.count});
}

/// Encabezado azul de la Sala (mockup 05)
@immutable
class MedicoQueueHeaderData {
  final int patientsInCare;
  final List<MedicoQueueLevelCount> levelCounts;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationTap;

  const MedicoQueueHeaderData({
    required this.patientsInCare,
    required this.levelCounts,
    this.hasUnreadNotifications = false,
    this.onNotificationTap,
  });
}
