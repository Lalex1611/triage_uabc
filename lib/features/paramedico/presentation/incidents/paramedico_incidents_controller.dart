import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_incidents_store.dart';

/// Lista de incidentes activos. Los datos son los del mapa
/// ([ParamedicoIncidentsStore]): abrir la lista no vuelve a pedirlos
class ParamedicoIncidentsController extends ChangeNotifier {
  ParamedicoIncidentsController({
    ParamedicoIncidentsStore? store,
    TextEditingController? searchController,
  }) : _store = store ?? ParamedicoIncidentsStore.instance,
       searchController = searchController ?? TextEditingController() {
    _store.addListener(notifyListeners);
  }

  final ParamedicoIncidentsStore _store;
  final TextEditingController searchController;

  List<ParamedicoIncidentSummary> get items => _store.incidents;
  Map<String, IncidentPatientTriageCounts> get counts => _store.counts;
  bool get loading => !_store.loaded && _store.error == null;
  String? get error => _store.error;
  String searchQuery = '';

  bool _disposed = false;

  // Una recarga puede terminar con la lista ya cerrada
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(notifyListeners);
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged(String value) {
    searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  /// Fuerza una recarga (deslizar para actualizar)
  Future<void> load() => _store.refresh();

  IncidentForCards toCard(ParamedicoIncidentSummary s, String uid) {
    return IncidentForCardsMapper.fromSummary(
      summary: s,
      counts: IncidentForCardsMapper.countsFor(s.id, counts),
      currentUserId: uid,
    );
  }
}
