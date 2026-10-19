/// Permite pausar las consultas sin confundir el límite con un código vencido.
class ConsultaRateLimitException implements Exception {
  const ConsultaRateLimitException();

  @override
  String toString() =>
      'Demasiadas consultas. Espera cinco minutos antes de intentarlo de nuevo.';
}
