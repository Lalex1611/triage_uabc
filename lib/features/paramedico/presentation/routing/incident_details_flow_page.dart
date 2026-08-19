import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_view_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_list_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_map_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_photos_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_stats_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';

// Ruta de detalle de incidente: enlaza IncidentDetailsController con IncidentDetailsPage
class IncidentDetailsFlowPage extends StatefulWidget {
  const IncidentDetailsFlowPage({super.key, required this.incidentId});

  final String incidentId;

  @override
  State<IncidentDetailsFlowPage> createState() =>
      _IncidentDetailsFlowPageState();
}

class _IncidentDetailsFlowPageState extends State<IncidentDetailsFlowPage> {
  late IncidentDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = IncidentDetailsController(incidentId: widget.incidentId);
    _controller.addListener(_onController);
    unawaited(_controller.load());
  }

  @override
  void didUpdateWidget(covariant IncidentDetailsFlowPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentId != widget.incidentId) {
      _controller.removeListener(_onController);
      _controller.dispose();
      _controller = IncidentDetailsController(incidentId: widget.incidentId);
      _controller.addListener(_onController);
      unawaited(_controller.load());
    }
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

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppHeader(
      type: HeaderType.incident,
      color: AppColors.primaryParamedico,
      isConnected: true,
      hasNotifications: false,
      backLabel: 'Regresar a Incidentes',
      actionLabel: _controller.canEditIncident ? 'Cerrar incidente' : null,
      onBack: () => _controller.leave(context),
      onAction: _controller.canEditIncident
          ? () => _controller.confirmClose(context)
          : null,
    );
  }

  Widget _tabBody(BuildContext context) {
    final inc = _controller.incident!;
    switch (_controller.activeTab) {
      case IncidentTabType.lista:
        return IncidentDetailsListTab(
          searchController: _controller.searchController,
          onSearchChanged: _controller.setPatientQuery,
          onRefresh: _controller.load,
          listHeaderData: IncidentDetailsViewMapper.listHeaderData(
            patientCount: _controller.patients.length,
            sortOption: _controller.sortOption,
            onSortChanged: _controller.setSortOption,
          ),
          triageFiltersData: IncidentDetailsViewMapper.triageFiltersData(
            activeFilter: _controller.triageFilter,
            onFilterChanged: _controller.setTriageFilter,
          ),
          emptyMessage: _controller.listEmptyMessage(),
          patientCards: _controller.patientCards(context),
        );
      case IncidentTabType.mapa:
        return IncidentDetailsMapTab(
          hasLocation: IncidentPresentationFormatters.hasIncidentLocation(inc),
          latitude: inc.latitude,
          longitude: inc.longitude,
          onOpenInteractiveMap: () => _controller.openInteractiveMap(context),
        );
      case IncidentTabType.fotos:
        return IncidentDetailsPhotosTab(
          description: inc.description,
          photos: inc.photoPaths,
          isEditable: _controller.canEditIncident,
          onSaveDescription: (description) =>
              _controller.saveIncidentDescription(context, description),
          onAddPhotoTap: () =>
              _controller.showIncidentImageSourceDialog(context),
          onRemovePhotoTap: (index) =>
              unawaited(_controller.removeIncidentPhotoAt(context, index)),
        );
      case IncidentTabType.estadisticas:
        return const IncidentDetailsStatsTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _controller.shellMode;
    final inc = _controller.incident;

    return IncidentDetailsPage(
      shellMode: mode,
      appBar: mode == IncidentDetailsShellMode.ready ? _appBar(context) : null,
      errorMessage: _controller.error,
      onBack: () => _controller.leave(context),
      headerData: inc != null ? _controller.headerData(context) : null,
      metadataData: inc != null ? _controller.metadataData() : null,
      tabSelectorData: inc != null ? _controller.tabSelectorData() : null,
      tabBody: inc != null ? _tabBody(context) : null,
      onStartTap: inc != null
          ? () => unawaited(_controller.openTriageAndRefresh(context))
          : null,
      onRegisterTap: inc != null
          ? () => unawaited(_controller.openRegisterAndRefresh(context))
          : null,
    );
  }
}
