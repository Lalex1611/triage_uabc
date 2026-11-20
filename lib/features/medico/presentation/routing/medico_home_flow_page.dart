import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_notification_item.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_home_controller.dart';
import 'package:sistema_triage/features/medico/presentation/home/medico_incoming_transfer_interactions.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
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
    final visible = c.visiblePatients(c.navIndex);

    return MedicoHomePage(
      navIndex: c.navIndex,
      onNavTap: c.setNavIndex,
      isConnected: true,
      userStats: c.statsFor(c.patients),
      searchController: c.searchController,
      onSearchChanged: c.onSearchChanged,
      patientCount: visible.length,
      activeFilter: c.activeFilter,
      onFilterChanged: c.setActiveFilter,
      showTriageFilters: false,
      errorMessage: c.error,
      loading: c.loading,
      onRefresh: c.load,
      contentSlivers: _buildContentSlivers(context, visible),
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

  List<Widget> _buildContentSlivers(
    BuildContext context,
    List<MedicoPatientCardData> visible,
  ) {
    final c = _controller;
    if (c.loading) return const [];

    if (c.navIndex == 0) {
      final incoming = c.incomingPatients(visible);
      final accepted = c.acceptedPatients(visible);
      final rejected = c.visibleRejected();
      return [
        SliverToBoxAdapter(
          child: _MedicoPatientQueueSectionHeader(
            title: 'Pacientes en camino (pendientes)',
            count: incoming.length,
          ),
        ),
        if (incoming.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(35, 0, 35, 12),
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
          _sliverPatientCards(context, incoming, c),
        SliverToBoxAdapter(
          child: _MedicoPatientQueueSectionHeader(
            title: 'Pacientes aceptados (recibidos)',
            count: accepted.length,
          ),
        ),
        if (accepted.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(35, 0, 35, 24),
              child: Text(
                'Sin pacientes recibidos.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
            ),
          )
        else
          _sliverPatientCards(context, accepted, c),
        SliverToBoxAdapter(
          child: _MedicoPatientQueueSectionHeader(
            title: 'Traslados rechazados',
            count: rejected.length,
          ),
        ),
        if (rejected.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(35, 0, 35, 24),
              child: Text(
                'Sin traslados rechazados.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
            ),
          )
        else
          _sliverPatientCards(context, rejected, c),
      ];
    }

    if (visible.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No hay pacientes en cola.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(35, 8, 35, 15),
        sliver: SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            return _patientCardWidget(context, visible[index], c);
          },
        ),
      ),
    ];
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

  Widget _sliverPatientCards(
    BuildContext context,
    List<MedicoPatientCardData> items,
    MedicoHomeController c,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(childCount: items.length * 2 - 1, (
          ctx,
          idx,
        ) {
          if (idx.isOdd) {
            return const SizedBox(height: 15);
          }
          final raw = items[idx ~/ 2];
          return _patientCardWidget(ctx, raw, c);
        }),
      ),
    );
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

class _MedicoPatientQueueSectionHeader extends StatelessWidget {
  const _MedicoPatientQueueSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 18, 35, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryMedico.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                fontSize: 13,
                color: AppColors.primaryMedico,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
