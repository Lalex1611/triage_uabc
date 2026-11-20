/// Respuesta a "¿Cuenta con seguro médico?" en el registro sin traslado
/// (mockup 07). [storedValue] es lo que se guarda en
/// `demographics.seguro_medico`; "No sabe" no guarda nada.
enum MedicoWalkInInsurance {
  si('Sí', 'si'),
  no('No', 'no'),
  noSabe('No sabe', null);

  final String label;
  final String? storedValue;

  const MedicoWalkInInsurance(this.label, this.storedValue);
}
