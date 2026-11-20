/// A dónde sale el paciente al darle de alta (mockup 10). [dbValue] es lo que
/// guarda `patient_discharges.destination`.
enum MedicoDischargeDestination {
  domicilio('domicilio', 'Alta a domicilio', 'Se retira por su propio pie'),
  hospitalizacion(
    'hospitalizacion',
    'Hospitalización',
    'Pasa a piso o a quirófano',
  ),
  traslado('traslado', 'Traslado a otra unidad', 'Se envía a otro hospital'),
  defuncion('defuncion', 'Defunción', 'Se documenta el desenlace');

  final String dbValue;
  final String title;
  final String subtitle;

  const MedicoDischargeDestination(this.dbValue, this.title, this.subtitle);

  static MedicoDischargeDestination? fromDb(String? raw) {
    for (final d in values) {
      if (d.dbValue == raw) return d;
    }
    return null;
  }
}
