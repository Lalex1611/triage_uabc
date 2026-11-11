import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_tab_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/incident_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_action_buttons_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_custom_tab_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/incident_details/widgets/incident_detail_header_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Cascarón de la vista de detalles de incidente (paramédico, B07 a B10)
class IncidentDetailsPage extends StatelessWidget {
  final IncidentDetailsShellMode shellMode;
  final String? errorMessage;
  final VoidCallback? onBack;
  final VoidCallback? onMoreTap;
  final IncidentHeaderData? headerData;
  final IncidentTabSelectorData? tabSelectorData;
  final Widget? tabBody;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onCloseIncidentTap;

  const IncidentDetailsPage({
    super.key,
    required this.shellMode,
    this.errorMessage,
    this.onBack,
    this.onMoreTap,
    this.headerData,
    this.tabSelectorData,
    this.tabBody,
    this.onRegisterTap,
    this.onCloseIncidentTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (shellMode) {
      case IncidentDetailsShellMode.loading:
        return _StateShell(
          onBack: onBack,
          child: const CircularProgressIndicator(
            color: TriageColors.paramedicAccent,
          ),
        );
      case IncidentDetailsShellMode.error:
        return _StateShell(
          onBack: onBack,
          child: Text(
            errorMessage ?? 'No encontrado.',
            textAlign: TextAlign.center,
            style: TriageTextStyles.bodyMedium.copyWith(
              color: TriageColors.textSecondary,
            ),
          ),
        );
      case IncidentDetailsShellMode.ready:
        return _ContentShell(
          onBack: onBack,
          onMoreTap: onMoreTap,
          headerData: headerData!,
          tabSelectorData: tabSelectorData!,
          tabBody: tabBody!,
          onRegisterTap: onRegisterTap,
          onCloseIncidentTap: onCloseIncidentTap,
        );
    }
  }
}

/// Encabezado y un contenido centrado, para los estados de carga y error
class _StateShell extends StatelessWidget {
  final VoidCallback? onBack;
  final Widget child;

  const _StateShell({required this.onBack, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TriageColors.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TriageDetailHeader(title: 'Incidente', onBack: onBack),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(TriageSpacing.xxl),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentShell extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onMoreTap;
  final IncidentHeaderData headerData;
  final IncidentTabSelectorData tabSelectorData;
  final Widget tabBody;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onCloseIncidentTap;

  const _ContentShell({
    required this.onBack,
    required this.onMoreTap,
    required this.headerData,
    required this.tabSelectorData,
    required this.tabBody,
    this.onRegisterTap,
    this.onCloseIncidentTap,
  });

  /// Parte máxima de la pantalla para los datos del incidente: con poca altura o
  /// texto grande se desplazan y dejan sitio al contenido de la pestaña
  static const _maxInfoShare = 0.3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TriageColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TriageDetailHeader(
              title: headerData.id,
              badge: headerData.isClosed
                  ? const TriageStatusBadge.closed()
                  : const TriageStatusBadge.active(),
              onBack: onBack,
              onMore: onMoreTap,
              showDivider: false,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * _maxInfoShare,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: IncidentDetailHeader(data: headerData),
              ),
            ),
            ColoredBox(
              color: TriageColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IncidentCustomTabBar(data: tabSelectorData),
                  const Divider(
                    height: TriageSizes.hairline,
                    thickness: TriageSizes.hairline,
                    color: TriageColors.borderSubtle,
                  ),
                ],
              ),
            ),
            Expanded(child: tabBody),
            IncidentActionButtons(
              isStatsTab:
                  tabSelectorData.activeTab == IncidentTabType.estadisticas,
              onRegisterTap: onRegisterTap,
              onCloseIncidentTap: onCloseIncidentTap,
            ),
          ],
        ),
      ),
    );
  }
}
