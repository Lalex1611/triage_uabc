import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/paramedico_home_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/paramedico_home_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/incident_card_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_session_actions.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Vista del tab principal (Home) para el rol de paramédico
class ParamedicoHomeTabPage extends StatefulWidget {
  const ParamedicoHomeTabPage({super.key});

  @override
  State<ParamedicoHomeTabPage> createState() => _ParamedicoHomeTabPageState();
}

class _ParamedicoHomeTabPageState extends State<ParamedicoHomeTabPage> {
  late final ParamedicoHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ParamedicoHomeController();
    _controller.searchController.addListener(_controller.onSearchChanged);
    _controller.addListener(_onController);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.searchController.removeListener(_controller.onSearchChanged);
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    List<ParamedicoIncidentSummary> filtered,
    String uid,
  ) {
    final hPad = context.horizontalPadding;

    if (filtered.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: const Center(
              child: Text(
                'No hay incidentes activos.\nToca + para crear uno.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 15),
        sliver: SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final inc = filtered[index];
            return IncidentCard(
              incident: _controller.toCard(inc, uid),
              onTap: () => pushParamedicoFullScreen(
                context,
                '/paramedico/incident/${inc.id}',
              ),
            );
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.shellMode == ParamedicoHomeShellMode.unconfigured) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _controller.error ?? 'Supabase no configurado.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final filtered = _controller.filteredIncidents(uid);

    return ParamedicoHomePage(
      header: AppHeader(
        type: HeaderType.home,
        color: AppColors.primaryParamedico,
        isConnected: true,
        hasNotifications: _controller.unreadNotifications > 0,
        subtitle: 'Cruz Roja - Tijuana',
        onNotificationTap: () => _controller.openNotifications(context),
        onProfileTap: () => ParamedicoSessionActions.openProfileSheet(context),
      ),
      userStats: _controller.userStats(),
      searchController: _controller.searchController,
      totalIncidents: _controller.incidents.length,
      mineOnly: _controller.mineOnly,
      onMineOnlyChanged: _controller.setMineOnly,
      sortOption: _controller.sort,
      onSortChanged: _controller.setSort,
      errorMessage: _controller.error,
      isLoading: _controller.loading,
      onRefresh: _controller.load,
      contentSlivers: _buildContentSlivers(context, filtered, uid),
      onCreateIncident: () =>
          pushParamedicoFullScreen(context, '/paramedico/incident/nuevo'),
    );
  }
}
