import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_body_kind.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/start_triage_tab_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_0_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_1_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_1_respira_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_2_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/guided_protocol/guided_protocol_step_3_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/photo_capture_area_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/selected_triage_pill_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_actions_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_name_input_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/start_triage_toggle_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/triage_color_grid_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/start_triage_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/start_triage_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_0_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_1_respira_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_1_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_2_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/guided_protocol/guided_protocol_step_3_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/photo_capture_area_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/selected_triage_pill_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_actions_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_name_input_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/start_triage_toggle_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_triage/widgets/triage_color_grid_widget.dart';

/// Flujo de asignación rápida y protocolo guiado de triage START
class StartTriageFlowPage extends StatefulWidget {
  const StartTriageFlowPage({
    super.key,
    this.incidentId,
    this.initialTab = StartTriageTabOption.asignacionRapida,
  });

  final String? incidentId;
  final StartTriageTabOption initialTab;

  @override
  State<StartTriageFlowPage> createState() => _StartTriageFlowPageState();
}

class _StartTriageFlowPageState extends State<StartTriageFlowPage> {
  late final StartTriageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StartTriageController(
      incidentId: widget.incidentId,
      initialTab: widget.initialTab,
    );
    _controller.addListener(_onController);
    unawaited(_controller.loadPatientNumber());
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

  List<Widget> _buildBodyForKind(
    BuildContext context,
    StartTriageController c,
  ) {
    switch (c.bodyKind) {
      case StartTriageBodyKind.postClasificacion:
        return [_buildPostClassificationBody(context, c)];
      case StartTriageBodyKind.asignacionRapida:
        return [
          _buildQuickAssignmentBody(context, c),
          const SizedBox(height: 32),
          StartTriageNameInputWidget(
            data: StartTriageNameInputData(onChanged: c.setPatientName),
          ),
        ];
      case StartTriageBodyKind.protocoloGuiado:
        return [_buildGuidedSteps(c)];
    }
  }

  Widget _buildGuidedSteps(StartTriageController c) {
    switch (c.protocolStep) {
      case 0:
        return GuidedProtocolStep0Widget(
          data: GuidedProtocolStep0Data(
            onYesTap: () => c.setSelectedCategory(TriageCategory.verde),
            onNoTap: () => c.setProtocolStep(1),
          ),
        );
      case 1:
        return GuidedProtocolStep1Widget(
          data: GuidedProtocolStep1Data(
            onYesTap: () => c.setProtocolStep(2),
            onNoTap: () => c.setSelectedCategory(TriageCategory.rojo),
          ),
        );
      case 2:
        return GuidedProtocolStep1RespiraWidget(
          data: GuidedProtocolStep1RespiraData(
            onRedButtonTap: () => c.setSelectedCategory(TriageCategory.rojo),
            onOrangeButtonTap: () => c.setProtocolStep(3),
          ),
        );
      case 3:
        return GuidedProtocolStep2Widget(
          data: GuidedProtocolStep2Data(
            onMenorTap: () => c.setProtocolStep(4),
            onMayorTap: () => c.setSelectedCategory(TriageCategory.rojo),
          ),
        );
      case 4:
        return GuidedProtocolStep3Widget(
          data: GuidedProtocolStep3Data(
            onYesTap: () => c.setSelectedCategory(TriageCategory.amarillo),
            onNoTap: () => c.setSelectedCategory(TriageCategory.rojo),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuickAssignmentBody(
    BuildContext context,
    StartTriageController c,
  ) {
    return TriageColorGridWidget(
      data: TriageColorGridData(
        categories: const [
          TriageCategory.rojo,
          TriageCategory.amarillo,
          TriageCategory.verde,
          TriageCategory.negro,
        ],
        onColorSelected: c.setSelectedCategory,
      ),
    );
  }

  Widget _buildPostClassificationBody(
    BuildContext context,
    StartTriageController c,
  ) {
    return Column(
      children: [
        SelectedTriagePillWidget(
          data: SelectedTriagePillData(category: c.selectedCategory!),
        ),
        const SizedBox(height: 24),
        PhotoCaptureAreaWidget(
          data: PhotoCaptureAreaData(
            photos: c.photos,
            onAddPhotoTap: () => c.showImageSourceDialog(context),
            onRemovePhotoTap: c.removePhotoAt,
          ),
        ),
        const SizedBox(height: 32),
        StartTriageActionsWidget(
          data: StartTriageActionsData(
            hasPhotos: c.photos.isNotEmpty,
            onCancelOrReturn: c.resetFlow,
            onSkip: () => unawaited(c.goRegister(context)),
            onRegister: () => unawaited(c.goRegister(context)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Theme(
      data: appTheme,
      child: StartTriagePage(
        children: [
          StartTriageHeaderWidget(
            data: StartTriageHeaderData(
              patientNumber: c.patientNumber,
              onCloseTap: () => c.leave(context),
            ),
          ),
          const SizedBox(height: 24),
          StartTriageToggleWidget(
            data: StartTriageToggleData(
              activeTab: c.activeTab,
              onTabChanged: c.setActiveTab,
            ),
          ),
          const SizedBox(height: 60),
          ..._buildBodyForKind(context, c),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
