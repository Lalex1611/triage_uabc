import 'package:flutter/material.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_incidents_store.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_notifications_action.dart';

enum ParamedicoIncidentsShellMode { unconfigured, loading, ready }

/// Lista de incidentes activos. Los datos son los del mapa
/// ([ParamedicoIncidentsStore]): abrir la lista no vuelve a pedirlos
class ParamedicoIncidentsController extends ChangeNotifier {
  ParamedicoIncidentsController({
    ParamedicoIncidentsStore? store,
    ParamedicNotificationsRepository? notificationsRepository,
    TextEditingController? searchController,
  }) : _store = store ?? ParamedicoIncidentsStore.instance,
       _notificationsRepo =
           notificationsRepository ?? ParamedicNotificationsRepository(),
       searchController = searchController ?? TextEditingController() {
    _store.addListener(notifyListeners);
  }

  final ParamedicoIncidentsStore _store;
  final ParamedicNotificationsRepository _notificationsRepo;
  final TextEditingController searchController;

  List<ParamedicoIncidentSummary> get items => _store.incidents;
  Map<String, IncidentPatientTriageCounts> get counts => _store.counts;
  bool get loading => !_store.loaded && _store.error == null;
  String? get error => _store.error;
  int unreadNotifications = 0;
  String searchQuery = '';

  ParamedicoIncidentsShellMode get shellMode {
    if (!SupabaseEnv.isConfigured) {
      return ParamedicoIncidentsShellMode.unconfigured;
    }
    if (loading) return ParamedicoIncidentsShellMode.loading;
    return ParamedicoIncidentsShellMode.ready;
  }

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

  List<ParamedicoIncidentSummary> get filteredItems {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (e) =>
              e.generatedTitle.toLowerCase().contains(q) ||
              e.id.toLowerCase().contains(q) ||
              e.emergencyType.toLowerCase().contains(q) ||
              (e.description ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  /// Fuerza una recarga (deslizar para actualizar) y el contador de avisos
  Future<void> load() async {
    await _store.refresh();
    unreadNotifications = await ParamedicoNotificationsAction.unreadCount(
      _notificationsRepo,
    );
    notifyListeners();
  }

  IncidentForCards toCard(ParamedicoIncidentSummary s, String uid) {
    return IncidentForCardsMapper.fromSummary(
      summary: s,
      counts: IncidentForCardsMapper.countsFor(s.id, counts),
      currentUserId: uid,
    );
  }

  Future<void> openNotifications(BuildContext context) async {
    await ParamedicoNotificationsAction.open(
      context,
      repository: _notificationsRepo,
      onUnreadChanged: (count) {
        unreadNotifications = count;
        notifyListeners();
      },
    );
  }
}
