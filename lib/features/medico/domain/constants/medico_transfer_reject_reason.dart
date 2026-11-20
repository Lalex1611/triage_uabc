/// Motivos para rechazar un traslado (mockup 04). El texto que recibe el
/// paramédico es [title] más el comentario opcional.
enum MedicoTransferRejectReason {
  sinCamas('Sin camas disponibles', 'Urgencias al límite de capacidad'),
  sinEspecialidad(
    'Sin especialidad requerida',
    'No contamos con el servicio que necesita',
  ),
  equipoOcupado(
    'Equipo o quirófano ocupado',
    'No hay recurso libre en este momento',
  ),
  otro('Otro motivo', 'Lo explico abajo');

  final String title;
  final String subtitle;

  const MedicoTransferRejectReason(this.title, this.subtitle);

  /// "Otro motivo" necesita el comentario para que el paramédico sepa por qué
  bool get requiresComment => this == MedicoTransferRejectReason.otro;

  /// Motivo que se guarda en `medico_rejected_transfers.reason` y se envía al
  /// paramédico en su notificación
  String reasonText(String comment) {
    final c = comment.trim();
    if (this == MedicoTransferRejectReason.otro) return c;
    return c.isEmpty ? title : '$title. $c';
  }
}
