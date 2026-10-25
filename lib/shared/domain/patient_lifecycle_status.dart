/// Estado del paciente; refleja `public.patient_lifecycle_status` en Postgres
///
/// Flujo: [waiting] → [transferring] → [received] → [discharged].
/// Único retroceso: [transferring] → [waiting] cuando el hospital cancela el traslado
/// (lo valida la BD). Fuente única para paramédico, médico y consulta externa.
///
/// Dart puro: la apariencia vive en `PatientLifecycleStatusStyle`
/// (`core/theme/patient_lifecycle_status_style.dart`).
enum PatientLifecycleStatus {
  waiting('en_espera'),
  transferring('trasladando'),
  received('recibido'),
  discharged('alta_medica');

  const PatientLifecycleStatus(this.dbValue);

  /// Valor en la columna `status`
  final String dbValue;

  static PatientLifecycleStatus? fromDb(String? raw) {
    for (final status in values) {
      if (status.dbValue == raw) return status;
    }
    return null;
  }
}
