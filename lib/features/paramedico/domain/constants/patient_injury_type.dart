/* / Tipos de lesión disponibles como chips en la descripción del paciente. */
enum PatientInjuryType {
  amputacion('Amputación'),
  lesionRespiratoria('Lesión respiratoria'),
  fractura('Fractura'),
  laceracion('Laceración'),
  quemadura('Quemadura'),
  traumatismoCraneal('Traumatismo craneal'),
  hemorragia('Hemorragia'),
  luxacion('Luxación');

  final String label;

  const PatientInjuryType(this.label);
}
