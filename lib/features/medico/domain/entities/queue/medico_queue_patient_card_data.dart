import 'package:flutter/foundation.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_category.dart';

@immutable
class MedicoQueuePatientCardData {
  final String patientId;
  final int level;
  final MedicoTriageCategory category;
  final String patientLine;
  final String ingressLabel;
  final String registrationDateTime;
  final VoidCallback onCardTap;
  final VoidCallback onCallTap;

  const MedicoQueuePatientCardData({
    required this.patientId,
    required this.level,
    required this.category,
    required this.patientLine,
    required this.ingressLabel,
    required this.registrationDateTime,
    required this.onCardTap,
    required this.onCallTap,
  });
}
