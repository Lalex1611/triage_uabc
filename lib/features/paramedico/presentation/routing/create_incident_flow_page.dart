import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/create_incident_actions_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/emergency_type_selector_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/gps_location_picker_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_description_section_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/incident_title_section_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/photo_upload_section_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_session_actions.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/app_header.dart';

class CreateIncidentFlowPage extends StatefulWidget {
  const CreateIncidentFlowPage({super.key});

  @override
  State<CreateIncidentFlowPage> createState() => _CreateIncidentFlowPageState();
}

class _CreateIncidentFlowPageState extends State<CreateIncidentFlowPage> {
  late final CreateIncidentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateIncidentController();
    _controller.addListener(_onController);
    unawaited(_controller.refreshNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.refreshGpsFromDevice(context, silent: true);
      if (mounted) await _controller.refreshPreviewTitle();
    });
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
    final c = _controller;
    return Theme(
      data: appTheme,
      child: CreateIncidentPage(
        appBar: AppHeader(
          type: HeaderType.paramedicoFlow,
          color: AppColors.primaryParamedico,
          isConnected: true,
          hasNotifications: c.unreadNotifications > 0,
          toolbarTitle: 'Nuevo incidente',
          onBack: () => context.pop(),
          onNotificationTap: () => unawaited(c.openNotifications(context)),
          onProfileTap: () =>
              ParamedicoSessionActions.openProfileSheet(context),
        ),
        stickyActionBar: CreateIncidentActions(
          onCancel: () => context.pop(),
          onCreate: c.submitting ? null : () => c.submit(context),
        ),
        children: [
          const SizedBox(height: 24),
          IncidentTitleSection(
            id: c.draftIdLabel,
            title: c.displayTitle,
            dateStr: IncidentPresentationFormatters.formatDateTime(
              c.capturedAt,
            ),
            onEditTap: () => unawaited(c.editTitle(context)),
          ),
          const SizedBox(height: 20),
          GpsLocationPicker(
            latitude: c.lat,
            longitude: c.lng,
            onShowMap: () => c.openLocationMap(context),
            onEditManual: () => c.openLocationMap(context),
          ),
          const SizedBox(height: 16),
          EmergencyTypeSelector(
            availableTypes: EmergencyCatalog.standardTypes,
            initialSelectedTypeId: EmergencyCatalog.defaultTypeId,
            onSelectionChanged: (id, _) => c.setEmergencyType(id),
          ),
          const SizedBox(height: 28),
          PhotoUploadSection(
            photos: c.photos,
            onAddPhotoTap: () => c.showImageSourceDialog(context),
            onRemovePhotoTap: c.removePhotoAt,
          ),
          const SizedBox(height: 28),
          IncidentDescriptionSection(controller: c.descriptionController),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
