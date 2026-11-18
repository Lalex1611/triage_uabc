import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Textos de un paciente entrante compartidos por la revisión (mockup 02) y
/// la confirmación de recepción (mockup 03)
abstract final class MedicoIncomingReviewFormat {
  static String priorityOf(TriageCategory c) => switch (c) {
    TriageCategory.rojo => 'INMEDIATO',
    TriageCategory.naranja => 'MUY URGENTE',
    TriageCategory.amarillo => 'URGENTE',
    TriageCategory.verde => 'POCO URGENTE',
    TriageCategory.azul => 'NO URGENTE',
    TriageCategory.negro => 'SIN SIGNOS VITALES',
    TriageCategory.todos => '',
  };

  /// "ROJO · INMEDIATO"
  static String levelBanner(TriageCategory c) =>
      '${c.label} · ${priorityOf(c)}';

  /// "Rojo · inmediato"
  static String levelSentence(TriageCategory c) {
    final color = c.label.toLowerCase();
    return '${color[0].toUpperCase()}${color.substring(1)} · '
        '${priorityOf(c).toLowerCase()}';
  }

  static int? minutesToArrival(MedicoIncomingReview r, DateTime now) =>
      r.estimatedArrivalAt?.difference(now).inMinutes;

  /// "Llega en 6 minutos · Unidad A-12" (tarjeta de la revisión)
  static String arrivalLong(MedicoIncomingReview r, DateTime now) {
    final mins = minutesToArrival(r, now);
    final when = mins == null
        ? 'En camino'
        : mins <= 0
        ? 'Llegando ahora'
        : mins == 1
        ? 'Llega en 1 minuto'
        : 'Llega en $mins minutos';
    return r.unitCode == null ? when : '$when · Unidad ${r.unitCode}';
  }

  /// "6 min · Unidad A-12" (resumen de la confirmación)
  static String arrivalShort(MedicoIncomingReview r, DateTime now) {
    final mins = minutesToArrival(r, now);
    final when = mins == null
        ? 'En camino'
        : mins <= 0
        ? 'Llegando'
        : '$mins min';
    return r.unitCode == null ? when : '$when · Unidad ${r.unitCode}';
  }

  /// "INC-729AB0 · Accidente vehicular"
  static String? incidentLabel(MedicoIncomingReview r) {
    if (r.incidentId == null) return null;
    return [
      IncidentPresentationFormatters.shortIncidentId(r.incidentId!),
      ?(r.emergencyTypeLabel ?? r.incidentTitle),
    ].join(' · ');
  }

  /// "INC-729AB0 · Carlos Huerta"
  static String originLabel(MedicoIncomingReview r) {
    final parts = [
      if (r.incidentId != null)
        IncidentPresentationFormatters.shortIncidentId(r.incidentId!),
      ?r.paramedicName,
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  static String hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
