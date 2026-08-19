import 'package:flutter/material.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_for_cards_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_notifications_action.dart';

enum ParamedicoIncidentsShellMode { unconfigured, loading, ready }

class ParamedicoIncidentsController extends ChangeNotifier {
  ParamedicoIncidentsController({
    ParamedicoIncidentsRepository? repository,
    ParamedicNotificationsRepository? notificationsRepository,
    TextEditingController? searchController,
  }) : _repo = repository ?? ParamedicoIncidentsRepository(),
       _notificationsRepo =
           notificationsRepository ?? ParamedicNotificationsRepository(),
       searchController = searchController ?? TextEditingController();

  final ParamedicoIncidentsRepository _repo;
  final ParamedicNotificationsRepository _notificationsRepo;
  final TextEditingController searchController;

  List<ParamedicoIncidentSummary> items = [];
  Map<String, IncidentPatientTriageCounts> counts = {};
  bool loading = true;
  String? error;
  int unreadNotifications = 0;
  String searchQuery = '';

  ParamedicoIncidentsShellMode get shellMode {
    if (!SupabaseEnv.isConfigured) {
      return ParamedicoIncidentsShellMode.unconfigured;
    }
    if (loading) return ParamedicoIncidentsShellMode.loading;
    return ParamedicoIncidentsShellMode.ready;
  }

  @override
  void dispose() {
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

  Future<void> load() async {
    if (!SupabaseEnv.isConfigured) {
      loading = false;
      error = 'Supabase no configurado.';
      items = [];
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      final list = await _repo.listOpenIncidents();
      final countMap = await _repo.patientTriageCountsByIncident(
        list.map((e) => e.id),
      );
      items = list;
      counts = countMap;
      loading = false;
      unreadNotifications = await ParamedicoNotificationsAction.unreadCount(
        _notificationsRepo,
      );
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
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
