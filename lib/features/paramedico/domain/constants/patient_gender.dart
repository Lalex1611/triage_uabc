/* / Género del paciente. */
enum PatientGender {
  masculino('M'),
  femenino('F');

  final String label;

  const PatientGender(this.label);
}
