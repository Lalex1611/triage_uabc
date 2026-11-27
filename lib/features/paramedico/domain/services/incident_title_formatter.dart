/// Sello de fecha y lugar: `d-mes-año HH:mm-nombreClaveUbicación`
/// (ej. 18-marzo-2026 14:32-Blvrd. 2000). Lo usa el nombre por defecto de los pacientes
class IncidentTitleFormatter {
  IncidentTitleFormatter._();

  static const _meses = <int, String>{
    1: 'enero',
    2: 'febrero',
    3: 'marzo',
    4: 'abril',
    5: 'mayo',
    6: 'junio',
    7: 'julio',
    8: 'agosto',
    9: 'septiembre',
    10: 'octubre',
    11: 'noviembre',
    12: 'diciembre',
  };

  static String formatAuto({
    required DateTime atLocal,
    required String locationKey,
  }) {
    final d = atLocal;
    final mes = _meses[d.month] ?? d.month.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}-$mes-${d.year} $hh:$mm-$locationKey';
  }
}
