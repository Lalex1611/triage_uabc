import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_user_stats.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_home_controller.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_incoming_transfer_interactions.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_home_page.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/medico_walk_in_register_tab.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_notifications_panel.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_incoming_transfer_shell.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
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
    _controller.startNotificationSubscription();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.searchController.removeListener(_onSearch);
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
      onProfileTap: () => ParamedicoSessionActions.confirmSignOut(context),
      walkInRegisterTab: MedicoWalkInRegisterTab(
        onSuccessfullyRegistered: (_) async {
          await _controller.load();
          _controller.setNavIndex(0);
        },
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    final c = _controller;
    if (c.loading) return const [];

    if (c.navIndex == 3) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _MedicoProfileCard(
              name: c.statsFor(c.patients).userName,
              stats: c.statsFor(c.patients),
            ),
          ),
        ),
      ];
    }

    if (c.navIndex == 1) {
      final accepted = c.acceptedPatients(c.patients);
      if (accepted.isEmpty) {
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Sin pacientes en sala.')),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          sliver: SliverList.separated(
            itemCount: accepted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _patientCardWidget(context, accepted[index], c);
            },
          ),
        ),
      ];
    }

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
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top,
              ),
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

    Future<void> accept() async {
      if (!mounted || id.isEmpty) return;
      final ok = await MedicoIncomingTransferInteractions.acceptIncoming(
        context: ctx,
        patientId: id,
      );
      if (ok && mounted) await c.load();
    }

    Future<void> reject() async {
      if (!mounted || id.isEmpty) return;
      final ok =
          await MedicoIncomingTransferInteractions.rejectIncomingTransfer(
            context: ctx,
            patientId: id,
          );
      if (ok && mounted) await c.load();
    }

    return raw.withIncomingTransferActions(
      onAccept: () => unawaited(accept()),
      onReject: () => unawaited(reject()),
      onTap: open,
    );
  }
}

class _MedicoProfileCard extends StatelessWidget {
  const _MedicoProfileCard({required this.name, required this.stats});

  final String name;
  final MedicoUserStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C69AA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÉDICO RECEPTOR',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Hospital General de Tijuana · Urgencias',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _row('Pacientes recibidos', '${stats.totalActive}'),
          _row('En camino', '${stats.enCaminoCount}'),
          _row('Críticos (rojo)', '${stats.rojoCriticoCount}'),
          _row('En sala', '${stats.enColaCount}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
