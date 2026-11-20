import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/features/medico/data/repositories/patients_repository.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_patient_filter.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_patient_status.dart';
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
    TextEditingController? salaSearchController,
  }) : _repo = repository ?? PatientsRepository(),
       searchController = searchController ?? TextEditingController(),
       salaSearchController = salaSearchController ?? TextEditingController();

  final PatientsRepository _repo;
  final TextEditingController searchController;

  /// Búsqueda propia de la pestaña Sala (independiente de Entrantes)
  final TextEditingController salaSearchController;
  MedicoQueueFilter salaFilter = MedicoQueueFilter.todos;
  String salaSearchQuery = '';

  /// Hora en que cada paciente pasó a `recibido` / `alta_medica`
  Map<String, DateTime> receivedAt = {};
  Map<String, DateTime> dischargedAt = {};

  List<MedicoPatientCardData> patients = [];
  List<MedicoPatientCardData> rejectedPatients = [];
  List<MedicoNotificationItem> medicoNotifications = [];
  bool loading = true;
  String? error;
  int navIndex = 0;
  MedicoPatientFilter activeFilter = MedicoPatientFilter.todos;
  String searchQuery = '';

  static const Duration _notificationPollInterval = Duration(seconds: 8);

  /// Red de seguridad por si Realtime se cae (o un cambio no llega por el
  /// filtro, p. ej. otro médico rechaza y el paciente queda sin hospital)
  static const Duration _patientsPollInterval = Duration(seconds: 30);

  /// Agrupa varios cambios seguidos en una sola recarga
  static const Duration _refreshDebounce = Duration(milliseconds: 600);

  Timer? _patientsPollTimer;
  Timer? _refreshDebounceTimer;
  RealtimeChannel? _patientsRealtimeChannel;
  bool _refreshing = false;
  bool _refreshPending = false;
  bool _disposed = false;

  /// Ids de notificaciones ya vistas; una nueva dispara recarga de pacientes
  final Set<String> _seenNotificationIds = {};
  bool _notificationsPrimed = false;

  Timer? _notificationPollTimer;
  RealtimeChannel? _notificationRealtimeChannel;

  /// Mantiene al día la campana y la lista de pacientes ("Llegando ahora",
  /// Sala) sin que el médico tenga que recargar
  void startLiveUpdates() {
    startNotificationSubscription();
    _startPatientsSubscription();
  }

  void stopLiveUpdates() {
    stopNotificationSubscription();
    _stopPatientsSubscription();
  }

  /// Realtime sobre `patients` del hospital del médico + polling de respaldo
  void _startPatientsSubscription() {
    _stopPatientsSubscription();
    if (!SupabaseEnv.isConfigured) return;

    _patientsPollTimer = Timer.periodic(
      _patientsPollInterval,
      (_) => requestSilentRefresh(),
    );

    final hid = AuthGate.instance.hospitalId;
    if (hid == null || hid.isEmpty) return;

    try {
      final channel = Supabase.instance.client.channel('medico_patients_$hid');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'patients',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'hospital_id',
          value: hid,
        ),
        callback: (_) => requestSilentRefresh(),
      );
      _patientsRealtimeChannel = channel;
      channel.subscribe();
    } catch (_) {
      // Sin Realtime quedan el polling y las notificaciones como respaldo
    }
  }

  void _stopPatientsSubscription() {
    _patientsPollTimer?.cancel();
    _patientsPollTimer = null;
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = null;
    final ch = _patientsRealtimeChannel;
    _patientsRealtimeChannel = null;
    if (ch != null && SupabaseEnv.isConfigured) {
      try {
        unawaited(Supabase.instance.client.removeChannel(ch));
      } catch (_) {}
    }
  }

  /// Pide una recarga de pacientes sin indicador de carga (agrupada)
  void requestSilentRefresh() {
    if (_disposed) return;
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(_refreshDebounce, () {
      unawaited(_silentRefresh());
    });
  }

  Future<void> _silentRefresh() async {
    if (_disposed || !SupabaseEnv.isConfigured) return;
    if (loading || _refreshing) {
      _refreshPending = true;
      return;
    }
    _refreshing = true;
    try {
      await _fetchPatients();
      if (_disposed) return;
      error = null;
      notifyListeners();
    } catch (_) {
      // Se conservan los datos anteriores; el siguiente cambio reintenta
    } finally {
      _refreshing = false;
      if (_refreshPending) {
        _refreshPending = false;
        requestSilentRefresh();
      }
    }
  }

  /// Si llegó una notificación que no habíamos visto, la lista de pacientes
  /// probablemente cambió (traslado nuevo, registro de otro médico, etc.)
  void _onNotificationsFetched(List<MedicoNotificationItem> items) {
    final ids = items.map((n) => n.id).toSet();
    final hasNew = ids.difference(_seenNotificationIds).isNotEmpty;
    _seenNotificationIds
      ..clear()
      ..addAll(ids);
    if (_notificationsPrimed && hasNew) requestSilentRefresh();
    _notificationsPrimed = true;
  }

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
              p.status == PatientStatus.enEspera,
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

  bool _matchesColor(MedicoPatientFilter f, MedicoPatientCardData p) {
    switch (f) {
      case MedicoPatientFilter.todos:
        return true;
      case MedicoPatientFilter.rojo:
        return p.triageCategory == TriageCategory.rojo;
      case MedicoPatientFilter.naranja:
        return p.triageCategory == TriageCategory.naranja;
      case MedicoPatientFilter.amarillo:
        return p.triageCategory == TriageCategory.amarillo;
      case MedicoPatientFilter.verde:
        return p.triageCategory == TriageCategory.verde;
    }
  }

  List<MedicoPatientCardData> filteredByChip() {
    return patients.where((p) => _matchesColor(activeFilter, p)).toList();
  }

  /// Pacientes aún no recibidos por el hospital, filtrados por color de triage
  List<MedicoPatientCardData> incomingPatientsFiltered() {
    final rejectedIds = _rejectedPatientIds();
    return patients
        .where(
          (p) =>
              (p.status == PatientStatus.trasladando ||
                  p.status == PatientStatus.enEspera) &&
              !rejectedIds.contains(p.patientRecordId) &&
              _matchesColor(activeFilter, p),
        )
        .toList();
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

  /// Pacientes aún no recibidos por el hospital (en espera o trasladando)
  List<MedicoPatientCardData> incomingPatients(
    List<MedicoPatientCardData> list,
  ) {
    final rejectedIds = _rejectedPatientIds();
    return list
        .where(
          (p) =>
              (p.status == PatientStatus.trasladando ||
                  p.status == PatientStatus.enEspera) &&
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
      _onNotificationsFetched(medicoNotifications);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markMedicoNotificationRead(String notificationId) async {
    try {
      await _repo.markMedicoNotificationRead(notificationId);
      await reloadNotificationsOnly();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Sala (mockup 05)
  // ---------------------------------------------------------------------------

  /// Estado visible en Sala; null si el paciente no está en sala
  MedicoQueuePatientStatus? salaStatusOf(MedicoPatientCardData p) {
    switch (p.status) {
      case PatientStatus.alta:
        return MedicoQueuePatientStatus.alta;
      case PatientStatus.recibido:
        return p.incidentId == null
            ? MedicoQueuePatientStatus.enEspera
            : MedicoQueuePatientStatus.recibido;
      case PatientStatus.enEspera:
      case PatientStatus.trasladando:
        return null;
    }
  }

  /// Pacientes en atención (recibidos, sin alta)
  List<MedicoPatientCardData> salaInCare() =>
      patients.where((p) => p.status == PatientStatus.recibido).toList();

  /// Conteo de pacientes en atención por color de triage
  int salaCountFor(TriageCategory category) =>
      salaInCare().where((p) => p.triageCategory == category).length;

  /// Lista de la Sala según chip + búsqueda.
  /// En atención: por nivel (más grave primero) y luego por llegada más antigua.
  /// Dados de alta: alta más reciente primero.
  List<MedicoPatientCardData> salaPatientsFiltered() {
    final q = salaSearchQuery.trim().toLowerCase();
    final list = patients.where((p) {
      final st = salaStatusOf(p);
      if (st == null) return false;
      final matchesChip = switch (salaFilter) {
        MedicoQueueFilter.todos => st != MedicoQueuePatientStatus.alta,
        MedicoQueueFilter.enEspera => st == MedicoQueuePatientStatus.enEspera,
        MedicoQueueFilter.recibidos => st == MedicoQueuePatientStatus.recibido,
        MedicoQueueFilter.dadosDeAlta => st == MedicoQueuePatientStatus.alta,
      };
      if (!matchesChip) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q);
    }).toList();

    if (salaFilter == MedicoQueueFilter.dadosDeAlta) {
      list.sort((a, b) {
        final ta = salaDischargedAt(a) ?? DateTime(0);
        final tb = salaDischargedAt(b) ?? DateTime(0);
        return tb.compareTo(ta);
      });
    } else {
      list.sort((a, b) {
        final byLevel = _severityRank(
          a.triageCategory,
        ).compareTo(_severityRank(b.triageCategory));
        if (byLevel != 0) return byLevel;
        final ta = salaArrivedAt(a) ?? DateTime.now();
        final tb = salaArrivedAt(b) ?? DateTime.now();
        return ta.compareTo(tb);
      });
    }
    return list;
  }

  /// Momento de llegada a sala: recepción del traslado o registro en ventanilla
  DateTime? salaArrivedAt(MedicoPatientCardData p) =>
      receivedAt[p.patientRecordId] ?? p.createdAt;

  DateTime? salaDischargedAt(MedicoPatientCardData p) =>
      dischargedAt[p.patientRecordId];

  static int _severityRank(TriageCategory c) {
    switch (c) {
      case TriageCategory.negro:
        return 0;
      case TriageCategory.rojo:
        return 1;
      case TriageCategory.naranja:
        return 2;
      case TriageCategory.amarillo:
        return 3;
      case TriageCategory.verde:
        return 4;
      case TriageCategory.azul:
        return 5;
      case TriageCategory.todos:
        return 6;
    }
  }

  void setSalaFilter(MedicoQueueFilter filter) {
    salaFilter = filter;
    notifyListeners();
  }

  void onSalaSearchChanged(String value) {
    salaSearchQuery = value;
    notifyListeners();
  }

  Future<void> _loadSalaTimestamps() async {
    final ids = patients
        .where(
          (p) =>
              p.status == PatientStatus.recibido ||
              p.status == PatientStatus.alta,
        )
        .map((p) => p.patientRecordId)
        .toList();
    try {
      final r = await _repo.fetchStatusTimestamps(ids);
      receivedAt = r.receivedAt;
      dischargedAt = r.dischargedAt;
    } catch (_) {
      // Sin historial: la Sala usa created_at como respaldo
      receivedAt = {};
      dischargedAt = {};
    }
  }

  void setNavIndex(int index) {
    navIndex = index.clamp(0, 3);
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
      await _fetchPatients();
      try {
        medicoNotifications = await _repo.fetchMedicoNotifications();
        _onNotificationsFetched(medicoNotifications);
      } catch (_) {
        medicoNotifications = [];
      }
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    } finally {
      // Un cambio que llegó durante la carga completa se aplica al terminar
      if (_refreshPending) {
        _refreshPending = false;
        requestSilentRefresh();
      }
    }
  }

  /// Pacientes del hospital, traslados rechazados y tiempos de la Sala.
  /// Los datos se reemplazan solo si todo se obtuvo bien.
  Future<void> _fetchPatients() async {
    final hid = AuthGate.instance.hospitalId;
    final list = await _repo.fetchForMedico(hospitalIdFromProfile: hid);
    var rejected = <MedicoPatientCardData>[];
    if (hid != null && hid.isNotEmpty) {
      try {
        rejected = await _repo.fetchRejectedTransfers(hospitalId: hid);
      } catch (_) {
        rejected = [];
      }
    }
    rejectedPatients = rejected;
    final rejectedIds = _rejectedPatientIds();
    patients = rejectedIds.isEmpty
        ? list
        : list.where((p) => !rejectedIds.contains(p.patientRecordId)).toList();
    await _loadSalaTimestamps();
  }

  /// Una carga puede terminar después de salir del inicio; en ese caso ya no
  /// hay a quién avisar
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopLiveUpdates();
    searchController.dispose();
    salaSearchController.dispose();
    super.dispose();
  }
}
