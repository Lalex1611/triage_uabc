import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/incident_sorting_options.dart';

/// Filtrado y orden de listas de incidentes abiertos (sin UI)
class IncidentListQuery {
  IncidentListQuery._();

  static List<ParamedicoIncidentSummary> filterAndSort({
    required List<ParamedicoIncidentSummary> incidents,
    required Map<String, IncidentPatientTriageCounts> countsByIncident,
    required String searchQuery,
    required bool mineOnly,
    required String currentUserId,
    required IncidentSortOption sortOption,
  }) {
    var list = List<ParamedicoIncidentSummary>.from(incidents);
    if (mineOnly) {
      list = list.where((e) => e.createdBy == currentUserId).toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.generatedTitle.toLowerCase().contains(q) ||
                e.id.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (sortOption) {
      case IncidentSortOption.recent:
        list.sort(
          (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)),
        );
      case IncidentSortOption.gravity:
        int score(String id) {
          final c = countsByIncident[id];
          if (c == null) return 0;
          return c.red * 5 + c.yellow * 3 + c.green;
        }
        list.sort((a, b) => score(b.id).compareTo(score(a.id)));
      case IncidentSortOption.victims:
        list.sort(
          (a, b) => (countsByIncident[b.id]?.total ?? 0).compareTo(
            countsByIncident[a.id]?.total ?? 0,
          ),
        );
    }
    return list;
  }
}
