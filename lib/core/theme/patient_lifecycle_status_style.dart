import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/patient_lifecycle_status.dart';

/// Apariencia de cada [PatientLifecycleStatus] en la insignia de estado (Figma
/// "TRIAGE/Insignia de estado")
///
/// [dotColor] y [background] siguen Figma; [textColor] usa los tonos `*Text`
/// cuando el de Figma no llega a 4.5:1 sobre su fondo.
extension PatientLifecycleStatusStyle on PatientLifecycleStatus {
  /// Texto visible; la insignia lo muestra en mayúsculas
  String get label => switch (this) {
    PatientLifecycleStatus.waiting => 'En espera',
    PatientLifecycleStatus.transferring => 'Trasladando',
    PatientLifecycleStatus.received => 'Recibido',
    PatientLifecycleStatus.discharged => 'Alta médica',
  };

  /// Punto de color de la insignia
  Color get dotColor => switch (this) {
    PatientLifecycleStatus.waiting => TriageColors.warning,
    PatientLifecycleStatus.transferring => TriageColors.hospitalAccent,
    PatientLifecycleStatus.received => TriageColors.info,
    PatientLifecycleStatus.discharged => TriageColors.success,
  };

  Color get textColor => switch (this) {
    PatientLifecycleStatus.waiting => TriageColors.warningText,
    PatientLifecycleStatus.transferring => TriageColors.hospitalAccent,
    PatientLifecycleStatus.received => TriageColors.infoText,
    PatientLifecycleStatus.discharged => TriageColors.successText,
  };

  Color get background => switch (this) {
    PatientLifecycleStatus.waiting => TriageColors.warningBackground,
    PatientLifecycleStatus.transferring => TriageColors.hospitalSoft,
    PatientLifecycleStatus.received => TriageColors.infoBackground,
    PatientLifecycleStatus.discharged => TriageColors.successBackground,
  };
}
