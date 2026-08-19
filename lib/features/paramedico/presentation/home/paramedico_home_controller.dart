import 'package:flutter/material.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/incident_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/home_user_stats.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_list_query.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_notifications_action.dart';

enum ParamedicoHomeShellMode { unconfigured, loading, ready }

class ParamedicoHomeController extends ChangeNotifier {
  ParamedicoHomeController({
    ParamedicoIncidentsRepository? repository,
    ParamedicNotificationsRepository? notificationsRepository,
    TextEditingController? searchController,
  })  : _repo = repository ?? ParamedicoIncidentsRepository(),
        _notificationsRepo = notificationsRepository ?? ParamedicNotificationsRepository(),
        searchController = searchController ?? TextEditingController();

  final ParamedicoIncidentsRepository _repo;
  final ParamedicNotificationsRepository _notificationsRepo;
  final TextEditingController searchController;

  List<ParamedicoIncidentSummary> incidents = [];
  Map<String, IncidentPatientTriageCounts> counts = {};
  bool loading = true;
  String? error;
  bool mineOnly = false;
  IncidentSortOption sort = IncidentSortOption.recent;
  String searchQuery = '';
  int unreadNotifications = 0;

  ParamedicoHomeShellMode get shellMode {
    if (!SupabaseEnv.isConfigured) return ParamedicoHomeShellMode.unconfigured;
    if (loading) return ParamedicoHomeShellMode.loading;
    return ParamedicoHomeShellMode.ready;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    searchQuery = searchController.text.trim().toLowerCase();
    notifyListeners();
  }

  void setMineOnly(bool value) {
    mineOnly = value;
    notifyListeners();
  }

  void setSort(IncidentSortOption option) {
    sort = option;
    notifyListeners();
  }

  Future<void> load() async {
    if (!SupabaseEnv.isConfigured) {
      loading = false;
      error =
          'Configura SUPABASE_URL y SUPABASE_ANON_KEY con --dart-define para usar datos reales.';
      incidents = [];
      counts = {};
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      final list = await _repo.listOpenIncidents();
      final countMap = await _repo.patientTriageCountsByIncident(list.map((e) => e.id));
      incidents = list;
      counts = countMap;
      loading = false;
      await _refreshNotificationCount();
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _refreshNotificationCount() async {
    unreadNotifications = await ParamedicoNotificationsAction.unreadCount(_notificationsRepo);
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

  HomeUserStats userStats() {
    final dash = _repo.dashboardStats(
      openIncidents: incidents,
      countsByIncident: counts,
    );
    return HomeUserStats(
      userName: AuthGate.instance.fullName ?? 'Paramédico',
      totalActive: dash.totalPatients,
      redCount: dash.redCount,
      yellowCount: dash.yellowCount,
      greenCount: dash.greenCount,
    );
  }

  List<ParamedicoIncidentSummary> filteredIncidents(String uid) {
    return IncidentListQuery.filterAndSort(
      incidents: incidents,
      countsByIncident: counts,
      searchQuery: searchQuery,
      mineOnly: mineOnly,
      currentUserId: uid,
      sortOption: sort,
    );
  }

  IncidentForCards toCard(ParamedicoIncidentSummary s, String uid) {
    return IncidentForCardsMapper.fromSummary(
      summary: s,
      counts: IncidentForCardsMapper.countsFor(s.id, counts),
      currentUserId: uid,
    );
  }
}
