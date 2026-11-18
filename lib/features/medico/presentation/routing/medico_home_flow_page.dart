import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_filter.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_queue_patient_status.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_filter_chips_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/queue/medico_queue_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/queue/medico_queue_page.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_home_controller.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_incoming_transfer_interactions.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_home_page.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/medico_walk_in_register_tab.dart';
import 'package:sistema_triage/features/medico/presentation/profile/medico_profile_tab.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_notifications_panel.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_incoming_transfer_shell.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_session_actions.dart';

/// Enlaza [MedicoHomeController] con [MedicoHomePage]
class MedicoHomeFlowPage extends StatefulWidget {
  const MedicoHomeFlowPage({super.key});

  @override
  State<MedicoHomeFlowPage> createState() => _MedicoHomeFlowPageState();
}

class _MedicoHomeFlowPageState extends State<MedicoHomeFlowPage>
    with WidgetsBindingObserver {
  late final MedicoHomeController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MedicoHomeController();
    _controller.addListener(_onController);
    _controller.searchController.addListener(_onSearch);
    _controller.salaSearchController.addListener(_onSalaSearch);
    _controller.startNotificationSubscription();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.searchController.removeListener(_onSearch);
    _controller.salaSearchController.removeListener(_onSalaSearch);
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  void _onSearch() {
    _controller.onSearchChanged(_controller.searchController.text);
  }

  void _onSalaSearch() {
    _controller.onSalaSearchChanged(_controller.salaSearchController.text);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.reloadNotificationsOnly());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return MedicoHomePage(
      navIndex: c.navIndex,
      onNavTap: (i) => c.setNavIndex(i.clamp(0, 3)),
      isConnected: true,
      userStats: c.statsFor(c.patients),
      searchController: c.searchController,
      onSearchChanged: c.onSearchChanged,
      activeFilter: c.activeFilter,
      onFilterChanged: c.setActiveFilter,
      showTriageFilters: true,
      errorMessage: c.error,
      loading: c.loading,
      onRefresh: c.load,
      contentSlivers: _buildContentSlivers(context),
      hasUnreadNotifications: c.hasUnreadMedicoNotifications,
      onNotificationTap: () => unawaited(_openNotifications(context)),
      onProfileTap: () => c.setNavIndex(3),
      salaTab: _buildSalaTab(context),
      profileTab: MedicoProfileTab(
        userName: c.statsFor(c.patients).userName,
        onBack: () => c.setNavIndex(0),
        onNotificationsTap: () => unawaited(_openNotifications(context)),
        onSignOut: () =>
            unawaited(ParamedicoSessionActions.confirmSignOut(context)),
      ),
      walkInRegisterTab: MedicoWalkInRegisterTab(
        onClose: ({required bool registered}) {
          c.setNavIndex(0);
          if (registered) unawaited(c.load());
        },
        onSuccessfullyRegistered: (_) async {
          // "Ver en la sala" (mockup 09): el paciente quedó «recibido»
          await c.load();
          c.setNavIndex(1);
        },
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    final c = _controller;
    if (c.loading) return const [];

    if (c.navIndex == 0) {
      final incoming = c.incomingPatientsFiltered();
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Llegando ahora',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.sort, size: 16, color: Colors.black54),
                    SizedBox(width: 4),
                    Text(
                      'Gravedad',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (incoming.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Sin pacientes en camino.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList.separated(
              itemCount: incoming.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _patientCardWidget(context, incoming[index], c);
              },
            ),
          ),
      ];
    }

    // navIndex == 2 (Registrar) no usa contentSlivers: MedicoHomePage
    // renderiza su propio Scaffold con walkInRegisterTab.
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Sala (mockup 05)
  // ---------------------------------------------------------------------------

  static const List<TriageCategory> _salaLevels = [
    TriageCategory.rojo,
    TriageCategory.naranja,
    TriageCategory.amarillo,
    TriageCategory.verde,
    TriageCategory.azul,
  ];

  Widget _buildSalaTab(BuildContext context) {
    final c = _controller;
    final list = c.salaPatientsFiltered();
    final emptyMessage = switch (c.salaFilter) {
      MedicoQueueFilter.todos => 'Sin pacientes en sala.',
      MedicoQueueFilter.enEspera => 'Sin pacientes en espera.',
      MedicoQueueFilter.recibidos => 'Sin pacientes recibidos.',
      MedicoQueueFilter.dadosDeAlta => 'Sin pacientes dados de alta.',
    };

    return MedicoQueuePage(
      header: MedicoQueueHeaderData(
        patientsInCare: c.salaInCare().length,
        levelCounts: [
          for (final cat in _salaLevels)
            MedicoQueueLevelCount(
              color: MedicoTriageLevel.colorOf(cat),
              count: c.salaCountFor(cat),
            ),
        ],
        hasUnreadNotifications: c.hasUnreadMedicoNotifications,
        onNotificationTap: () => unawaited(_openNotifications(context)),
      ),
      searchController: c.salaSearchController,
      filters: MedicoQueueFilterChipsData(
        selectedFilter: c.salaFilter,
        onFilterSelected: c.setSalaFilter,
      ),
      patients: [for (final p in list) _salaCardData(context, p, c)],
      loading: c.loading,
      errorMessage: c.error,
      emptyMessage: emptyMessage,
      onRefresh: c.load,
    );
  }

  MedicoQueuePatientCardData _salaCardData(
    BuildContext context,
    MedicoPatientCardData p,
    MedicoHomeController c,
  ) {
    final status = c.salaStatusOf(p) ?? MedicoQueuePatientStatus.recibido;
    final String subtitle;
    if (status == MedicoQueuePatientStatus.alta) {
      final at = c.salaDischargedAt(p);
      subtitle = at != null
          ? 'Alta ${_relativeTime(at).toLowerCase()}'
          : 'Alta médica';
    } else {
      final at = c.salaArrivedAt(p);
      final origin = p.incidentId != null
          ? 'del incidente ${IncidentPresentationFormatters.shortIncidentId(p.incidentId!)}'
          : 'llegó por su cuenta';
      subtitle = at != null ? '${_relativeTime(at)} · $origin' : origin;
    }

    return MedicoQueuePatientCardData(
      level: MedicoTriageLevel.levelOf(p.triageCategory),
      levelColor: MedicoTriageLevel.colorOf(p.triageCategory),
      name: p.name,
      status: status,
      subtitle: subtitle,
      onTap: () => unawaited(_openPatient(context, p, c)),
    );
  }

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    final days = diff.inDays;
    return days == 1 ? 'Hace 1 día' : 'Hace $days días';
  }

  Future<void> _openNotifications(BuildContext context) async {
    final c = _controller;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            return Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: MedicoNotificationsPanel(
                items: List<MedicoNotificationItem>.of(c.medicoNotifications),
                onItemTap: (item) async {
                  if (item.isUnread) {
                    await c.markMedicoNotificationRead(item.id);
                  }
                  final pid = item.patientId;
                  if (pid != null && pid.isNotEmpty && context.mounted) {
                    Navigator.of(sheetCtx).pop();
                    final r = await context.push<bool>('/medico/paciente/$pid');
                    if (context.mounted && r == true) await c.load();
                  }
                },
              ),
            );
          },
        );
      },
    );
    if (mounted) await c.reloadNotificationsOnly();
  }

  Widget _patientCardWidget(
    BuildContext context,
    MedicoPatientCardData raw,
    MedicoHomeController c,
  ) {
    final data = _patientCardPayload(context, raw, c);
    final showIncomingShell =
        data.status == PatientStatus.trasladando &&
        data.onIncomingAcceptTap != null &&
        data.onIncomingRejectTap != null;
    if (showIncomingShell) {
      return MedicoPatientIncomingTransferShell(data: data);
    }
    return MedicoPatientCard(data: data.withoutIncomingCallbacks());
  }

  Future<void> _openPatient(
    BuildContext context,
    MedicoPatientCardData raw,
    MedicoHomeController c,
  ) async {
    final id = raw.patientRecordId;
    if (id.isEmpty) return;
    final r = await context.push<bool>('/medico/paciente/$id');
    if (r == true && context.mounted) await c.load();
  }

  MedicoPatientCardData _patientCardPayload(
    BuildContext ctx,
    MedicoPatientCardData raw,
    MedicoHomeController c,
  ) {
    void open() => unawaited(_openPatient(ctx, raw, c));

    if (raw.status != PatientStatus.trasladando) {
      return raw.copyWith(onCardTap: open);
    }

    final id = raw.patientRecordId;

    Future<void> reject() async {
      if (!mounted || id.isEmpty) return;
      final ok =
          await MedicoIncomingTransferInteractions.rejectIncomingTransfer(
            context: ctx,
            patientId: id,
          );
      if (ok && mounted) await c.load();
    }

    // "Revisar y aceptar" abre la revisión del paciente (mockup 02); ahí el
    // médico confirma la recepción o rechaza el traslado
    return raw.withIncomingTransferActions(
      onAccept: open,
      onReject: () => unawaited(reject()),
      onTap: open,
    );
  }
}
