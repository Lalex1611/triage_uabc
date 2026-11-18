import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_patient_status.dart';

/// Datos de una tarjeta de paciente en la Sala (mockup 05)
@immutable
class MedicoQueuePatientCardData {
  /// Nivel de triage hospitalario (1 = rojo … 5 = azul); null si no aplica
  final int? level;
  final Color levelColor;
  final String name;
  final MedicoQueuePatientStatus status;

  /// p. ej. «Hace 4 min · del incidente INC-729»
  final String subtitle;
  final VoidCallback? onTap;

  const MedicoQueuePatientCardData({
    required this.level,
    required this.levelColor,
    required this.name,
    required this.status,
    required this.subtitle,
    this.onTap,
  });
}
