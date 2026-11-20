/// Instituciones de seguro médico más comunes en México. "Otra" permite
/// escribir el nombre.
abstract final class MedicoInsuranceInstitution {
  static const other = 'Otra';

  static const options = <String>[
    'IMSS',
    'ISSSTE',
    'IMSS-Bienestar',
    'ISSSTECALI',
    'Pemex',
    'Sedena / Semar',
    'Seguro privado',
    other,
  ];

  /// Opción del catálogo para un valor guardado; lo que no está en la lista
  /// cae en "Otra"
  static String? optionFor(String? stored) {
    if (stored == null || stored.trim().isEmpty) return null;
    for (final o in options) {
      if (o.toLowerCase() == stored.trim().toLowerCase()) return o;
    }
    return other;
  }
}
