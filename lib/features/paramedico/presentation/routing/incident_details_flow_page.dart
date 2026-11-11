import 'dart:async';

import 'package:flutter/material.dart';
//import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_view_mapper.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_list_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_map_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_photos_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_details_stats_tab_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_more_actions_sheet_widget.dart';

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

  void _showMoreActions(BuildContext context) {
    final header = _controller.headerData();
    showIncidentMoreActions(
      context,
      title: '${header.id} · ${header.title}',
      onEditTitle: () => unawaited(_controller.editIncidentTitle(context)),
      onEditLocation: () => unawaited(_controller.editIncidentCoords(context)),
      onAddPhotos: () => _controller.showIncidentImageSourceDialog(context),
      onCloseIncident: _controller.canCloseIncident
          ? () => unawaited(_controller.confirmClose(context))
          : null,
    );
  }

  Widget _tabBody(BuildContext context) {
    final inc = _controller.incident!;
    switch (_controller.activeTab) {
      case IncidentTabType.lista:
        return IncidentDetailsListTab(
          onRefresh: _controller.load,
          triageFiltersData: IncidentDetailsViewMapper.triageFiltersData(
            activeFilter: _controller.triageFilter,
            onFilterChanged: _controller.setTriageFilter,
          ),
          emptyMessage: _controller.listEmptyMessage(),
          patientCards: _controller.patientCards(context),
        );
      case IncidentTabType.mapa:
        return IncidentDetailsMapTab(
          latitude: inc.latitude,
          longitude: inc.longitude,
          patients: _controller.mapPatients,
          onPatientTap: (id) => _controller.openPatient(context, id),
        );
      case IncidentTabType.fotos:
        return IncidentDetailsPhotosTab(
          description: inc.description,
          photos: _controller.incidentPhotos,
          isEditable: _controller.canEditIncident,
          isUploading: _controller.uploadingPhoto,
          onSaveDescription: (description) =>
              _controller.saveIncidentDescription(context, description),
          onAddPhotoTap: () =>
              _controller.showIncidentImageSourceDialog(context),
          onRemovePhoto: (index) =>
              _controller.confirmRemoveIncidentPhoto(context, index),
        );
      case IncidentTabType.estadisticas:
        return IncidentDetailsStatsTab(patients: _controller.patients);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _controller.shellMode;
    final inc = _controller.incident;

    return IncidentDetailsPage(
      shellMode: mode,
      errorMessage: _controller.error,
      onBack: () => _controller.leave(context),
      onMoreTap: _controller.canEditIncident
          ? () => _showMoreActions(context)
          : null,
      headerData: inc != null ? _controller.headerData() : null,
      tabSelectorData: inc != null ? _controller.tabSelectorData() : null,
      tabBody: inc != null ? _tabBody(context) : null,
      onRegisterTap: inc != null
          ? () => unawaited(_controller.openRegistration(context))
          : null,
      onCloseIncidentTap: _controller.canCloseIncident
          ? () => unawaited(_controller.confirmClose(context))
          : null,
    );
  }
}
