import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Convierte resúmenes de incidente en entidad para [IncidentCard]
class IncidentForCardsMapper {
  IncidentForCardsMapper._();

  static IncidentForCards fromSummary({
    required ParamedicoIncidentSummary summary,
    required IncidentPatientTriageCounts counts,
    required String currentUserId,
  }) {
    return IncidentForCards(
      id: IncidentPresentationFormatters.shortIncidentId(summary.id).replaceFirst('#', ''),
      name_card: summary.generatedTitle,
      dateTime: summary.createdAt ?? DateTime.now(),
      latitude: summary.latitude ?? 0.0,
      longitude: summary.longitude ?? 0.0,
      red: counts.red,
      yellow: counts.yellow,
      green: counts.green,
      black: counts.black,
      totalVictims: counts.total,
      isMine: summary.createdBy == currentUserId,
    );
  }

  static IncidentPatientTriageCounts countsFor(
    String incidentId,
    Map<String, IncidentPatientTriageCounts> countsByIncident,
  ) {
    return countsByIncident[incidentId] ??
        IncidentPatientTriageCounts(red: 0, yellow: 0, green: 0, black: 0, total: 0);
  }
}
