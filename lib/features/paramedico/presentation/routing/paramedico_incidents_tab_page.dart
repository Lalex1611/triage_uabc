import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/features/paramedico/presentation/home/widgets/incident_card_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incidents/paramedico_incidents_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incidents/paramedico_incidents_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_session_actions.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParamedicoIncidentsTabPage extends StatefulWidget {
  const ParamedicoIncidentsTabPage({super.key});

  @override
  State<ParamedicoIncidentsTabPage> createState() =>
      _ParamedicoIncidentsTabPageState();
}

class _ParamedicoIncidentsTabPageState
    extends State<ParamedicoIncidentsTabPage> {
  late final ParamedicoIncidentsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ParamedicoIncidentsController();
    _controller.addListener(_onController);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.shellMode == ParamedicoIncidentsShellMode.unconfigured) {
      return Scaffold(
        body: Center(
          child: Text(_controller.error ?? 'Supabase no configurado.'),
        ),
      );
    }

    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';

    final visibleItems = _controller.filteredItems;
    final list = visibleItems.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 48),
              Center(
                child: Text(
                  _controller.items.isEmpty
                      ? 'No hay incidentes activos.'
                      : 'No hay incidentes con ese criterio.',
                ),
              ),
            ],
          )
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: visibleItems.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final inc = visibleItems[i];
              return IncidentCard(
                incident: _controller.toCard(inc, uid),
                onTap: () => pushParamedicoFullScreen(
                  context,
                  '/paramedico/incident/${inc.id}',
                ),
              );
            },
          );

    return ParamedicoIncidentsPage(
      header: AppHeader(
        type: HeaderType.search,
        color: AppColors.primaryParamedico,
        isConnected: true,
        hasNotifications: _controller.unreadNotifications > 0,
        onBack: () => context.go('/paramedico/home'),
        onNotificationTap: () => _controller.openNotifications(context),
        onProfileTap: () => ParamedicoSessionActions.openProfileSheet(context),
        searchController: _controller.searchController,
        onSearchChanged: _controller.onSearchChanged,
        searchHint: 'Buscar incidentes',
      ),
      errorMessage: _controller.error,
      isLoading: _controller.loading,
      onRefresh: _controller.load,
      incidentList: list,
      onCreateIncident: () =>
          pushParamedicoFullScreen(context, '/paramedico/incident/nuevo'),
    );
  }
}
