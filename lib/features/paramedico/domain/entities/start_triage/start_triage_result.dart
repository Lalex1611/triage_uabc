import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

/// Resultado al cerrar START TRIAGE en modo registro rápido (sin incidente previo)
class StartTriageResult {
  final TriageCategory triage;
  final String? displayName;

  const StartTriageResult({
    required this.triage,
    this.displayName,
  });
}
