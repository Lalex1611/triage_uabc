import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_filter.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_user_stats.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Orquestador del home médico: lista de pacientes, filtros y acciones de traslado
class MedicoHomeController extends ChangeNotifier {
  MedicoHomeController({
    PatientsRepository? repository,
    TextEditingController? searchController,
  }) : _repo = repository ?? PatientsRepository(),
       searchController = searchController ?? TextEditingController();

  final PatientsRepository _repo;
  final TextEditingController searchController;

  List<MedicoPatientCardData> patients = [];
  List<MedicoPatientCardData> rejectedPatients = [];
  List<MedicoNotificationItem> medicoNotifications = [];
  bool loading = true;
  String? error;
  int navIndex = 0;
  MedicoPatientFilter activeFilter = MedicoPatientFilter.enCamino;
  String searchQuery = '';

  static const Duration _notificationPollInterval = Duration(seconds: 8);

  Timer? _notificationPollTimer;
  RealtimeChannel? _notificationRealtimeChannel;

  /// Polling + Realtime (si la tabla está en `supabase_realtime`) para que la campana
  /// y el panel vean notificaciones nuevas sin salir del home
  void startNotificationSubscription() {
    stopNotificationSubscription();
    if (!SupabaseEnv.isConfigured) return;

    unawaited(reloadNotificationsOnly());

    _notificationPollTimer = Timer.periodic(_notificationPollInterval, (_) {
      unawaited(reloadNotificationsOnly());
    });

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final channel = Supabase.instance.client.channel(
        'medico_notifications_$uid',
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'medico_notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: uid,
        ),
        callback: (_) {
          unawaited(reloadNotificationsOnly());
        },
      );
      _notificationRealtimeChannel = channel;
      channel.subscribe();
    } catch (_) {
      // Si Realtime no está habilitado para la tabla, solo queda el polling
    }
  }

  void stopNotificationSubscription() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = null;
    final ch = _notificationRealtimeChannel;
    _notificationRealtimeChannel = null;
    if (ch != null && SupabaseEnv.isConfigured) {
      try {
        unawaited(Supabase.instance.client.removeChannel(ch));
      } catch (_) {}
    }
  }

  MedicoUserStats statsFor(List<MedicoPatientCardData> list) {
    final name = AuthGate.instance.fullName ?? 'Médico';
    final active = list.where((p) => p.status != PatientStatus.alta).length;
    final camino = list
        .where(
          (p) =>
              p.status == PatientStatus.trasladando ||
              p.status == PatientStatus.enEspera
        )
        .length;
    final rojo = list
        .where((p) => p.triageCategory == TriageCategory.rojo)
        .length;
    final cola = list.where((p) => p.status == PatientStatus.recibido).length;

    return MedicoUserStats(
      userName: name,
      totalActive: active,
      enCaminoCount: camino,
      rojoCriticoCount: rojo,
      enColaCount: cola,
    );
  }

  bool matchesChip(MedicoPatientFilter f, PatientStatus s) {
    switch (f) {
      case MedicoPatientFilter.enCamino:
        return s == PatientStatus.trasladando ||
            s == PatientStatus.enEspera;
      case MedicoPatientFilter.recibidos:
        return s == PatientStatus.recibido;
      case MedicoPatientFilter.independientes:
        return s == PatientStatus.enEspera;
      case MedicoPatientFilter.triageHospitalario:
        return true;
    }
  }

  List<MedicoPatientCardData> filteredByChip() {
    return patients.where((p) => matchesChip(activeFilter, p.status)).toList();
  }

  List<MedicoPatientCardData> visiblePatients(int navIdx) {
    final List<MedicoPatientCardData> base;
    if (navIdx == 0) {
      base = patients.where((p) => p.status != PatientStatus.alta).toList();
    } else {
      base = filteredByChip();
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Pacientes aún no recibidos por el hospital (mismo criterio que el filtro «En camino»)
  List<MedicoPatientCardData> incomingPatients(
    List<MedicoPatientCardData> list,
  ) {
    final rejectedIds = _rejectedPatientIds();
    return list
        .where(
          (p) =>
              matchesChip(MedicoPatientFilter.enCamino, p.status) &&
              !rejectedIds.contains(p.patientRecordId),
        )
        .toList();
  }

  List<MedicoPatientCardData> acceptedPatients(
    List<MedicoPatientCardData> list,
  ) {
    final rejectedIds = _rejectedPatientIds();
    return list
        .where(
          (p) =>
              p.status == PatientStatus.recibido &&
              !rejectedIds.contains(p.patientRecordId),
        )
        .toList();
  }

  Set<String> _rejectedPatientIds() => rejectedPatients
      .map((p) => p.patientRecordId)
      .where((id) => id.isNotEmpty)
      .toSet();

  bool get hasUnreadMedicoNotifications =>
      medicoNotifications.any((n) => n.isUnread);

  List<MedicoPatientCardData> visibleRejected() {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return rejectedPatients;
    return rejectedPatients
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> reloadNotificationsOnly() async {
    if (!SupabaseEnv.isConfigured) {
      medicoNotifications = [];
      notifyListeners();
      return;
    }
    try {
      medicoNotifications = await _repo.fetchMedicoNotifications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markMedicoNotificationRead(String notificationId) async {
    try {
      await _repo.markMedicoNotificationRead(notificationId);
      await reloadNotificationsOnly();
    } catch (_) {}
  }

  void setNavIndex(int index) {
    navIndex = index.clamp(0, 1);
    notifyListeners();
  }

  void setActiveFilter(MedicoPatientFilter filter) {
    activeFilter = filter;
    notifyListeners();
  }

  void onSearchChanged(String value) {
    searchQuery = value;
    notifyListeners();
  }

  Future<void> load() async {
    if (!SupabaseEnv.isConfigured) {
      loading = false;
      error =
          'Configura SUPABASE_URL y SUPABASE_ANON_KEY con --dart-define para cargar pacientes.';
      patients = [];
      rejectedPatients = [];
      medicoNotifications = [];
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final hid = AuthGate.instance.hospitalId;
      final list = await _repo.fetchForMedico(hospitalIdFromProfile: hid);
      rejectedPatients = [];
      if (hid != null && hid.isNotEmpty) {
        try {
          rejectedPatients = await _repo.fetchRejectedTransfers(
            hospitalId: hid,
          );
        } catch (_) {
          rejectedPatients = [];
        }
      }
      final rejectedIds = _rejectedPatientIds();
      patients = rejectedIds.isEmpty
          ? list
          : list
                .where((p) => !rejectedIds.contains(p.patientRecordId))
                .toList();
      try {
        medicoNotifications = await _repo.fetchMedicoNotifications();
      } catch (_) {
        medicoNotifications = [];
      }
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopNotificationSubscription();
    searchController.dispose();
    super.dispose();
  }
}
