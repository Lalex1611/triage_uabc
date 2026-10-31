import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_metadata_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_action_buttons_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_custom_tab_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_detail_header_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Cascarón de la vista de detalles de incidente (paramédico)
class IncidentDetailsPage extends StatelessWidget {
  final IncidentDetailsShellMode shellMode;
  final PreferredSizeWidget? appBar;
  final String? errorMessage;
  final VoidCallback? onBack;
  final IncidentHeaderData? headerData;
  final IncidentMetadataData? metadataData;
  final IncidentTabSelectorData? tabSelectorData;
  final Widget? tabBody;
  final VoidCallback? onStartTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onCloseIncidentTap;

  const IncidentDetailsPage({
    super.key,
    required this.shellMode,
    this.appBar,
    this.errorMessage,
    this.onBack,
    this.headerData,
    this.metadataData,
    this.tabSelectorData,
    this.tabBody,
    this.onStartTap,
    this.onRegisterTap,
    this.onCloseIncidentTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (shellMode) {
      case IncidentDetailsShellMode.loading:
        return _LoadingShell(appBar: appBar, onBack: onBack);
      case IncidentDetailsShellMode.error:
        return _ErrorShell(
          appBar: appBar,
          message: errorMessage ?? 'No encontrado.',
          onBack: onBack,
        );
      case IncidentDetailsShellMode.ready:
        return _ContentShell(
          appBar: appBar,
          headerData: headerData!,
          metadataData: metadataData!,
          tabSelectorData: tabSelectorData!,
          tabBody: tabBody!,
          onStartTap: onStartTap,
          onRegisterTap: onRegisterTap,
          onCloseIncidentTap: onCloseIncidentTap,
        );
    }
  }
}

class _LoadingShell extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final VoidCallback? onBack;

  const _LoadingShell({this.appBar, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TriageColors.canvas,
      appBar:
          appBar ??
          AppBar(
            backgroundColor: TriageColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const TriageIcon(
                TriageIcons.arrowLeft,
                color: TriageColors.textPrimary,
              ),
              onPressed: onBack,
            ),
          ),
      body: const Center(
        child: CircularProgressIndicator(color: TriageColors.paramedicAccent),
      ),
    );
  }
}

class _ErrorShell extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final String message;
  final VoidCallback? onBack;

  const _ErrorShell({this.appBar, required this.message, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TriageColors.canvas,
      appBar:
          appBar ??
          AppBar(
            backgroundColor: TriageColors.surface,
            elevation: 0,
            title: Text(
              'Incidente',
              style: TriageTextStyles.titleSmall.copyWith(
                color: TriageColors.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: const TriageIcon(
                TriageIcons.arrowLeft,
                color: TriageColors.textPrimary,
              ),
              onPressed: onBack,
            ),
          ),
      body: Center(
        child: Text(
          message,
          style: TriageTextStyles.bodyMedium.copyWith(
            color: TriageColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ContentShell extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final IncidentHeaderData headerData;
  final IncidentMetadataData metadataData;
  final IncidentTabSelectorData tabSelectorData;
  final Widget tabBody;
  final VoidCallback? onStartTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onCloseIncidentTap;

  const _ContentShell({
    this.appBar,
    required this.headerData,
    required this.metadataData,
    required this.tabSelectorData,
    required this.tabBody,
    this.onStartTap,
    this.onRegisterTap,
    this.onCloseIncidentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TriageColors.canvas,
      appBar: appBar,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IncidentDetailHeader(data: headerData),
                      //Transform.translate(
                      //  offset: const Offset(0, -15),
                      //  child: IncidentMetadataCard(data: metadataData),
                      //),
                    ],
                  ),
                ),
              ),
              ColoredBox(
                color: TriageColors.sunken,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    IncidentCustomTabBar(data: tabSelectorData),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(color: TriageColors.canvas, child: tabBody),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: IncidentActionButtons(
              isStatsTab:
                  tabSelectorData.activeTab == IncidentTabType.estadisticas,
              onStartTap: onStartTap,
              onRegisterTap: onRegisterTap,
              onCloseIncidentTap: onCloseIncidentTap,
            ),
          ),
        ],
      ),
    );
  }
}
