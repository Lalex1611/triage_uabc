/* / Tipos de sangre disponibles para el registro del paciente. */
enum PatientBloodType {
  aPositivo('A+'),
  aNegativo('A-'),
  bPositivo('B+'),
  bNegativo('B-'),
  abPositivo('AB+'),
  abNegativo('AB-'),
  oPositivo('O+'),
  oNegativo('O-');

  final String label;

  const PatientBloodType(this.label);
}
