import 'package:flutter/material.dart';

/// Estado visible de un paciente dentro de la Sala (mockup 05).
///
/// - [enEspera]: llegó por su cuenta (registro en ventanilla) y espera atención.
/// - [recibido]: llegó en traslado y el hospital confirmó la recepción.
/// - [alta]: ya recibió alta médica.
enum MedicoQueuePatientStatus {
  enEspera('EN ESPERA', Color(0xFFC2620A), Color(0xFFFDEBD3)),
  recibido('RECIBIDO', Color(0xFF0E7490), Color(0xFFD5EEF3)),
  alta('ALTA', Color(0xFF2E7D32), Color(0xFFDCEFDC));

  final String label;
  final Color foreground;
  final Color background;

  const MedicoQueuePatientStatus(this.label, this.foreground, this.background);
}
