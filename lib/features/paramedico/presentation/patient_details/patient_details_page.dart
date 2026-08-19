import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_photo_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_details/details_status_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_record_app_bar_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_status_strip_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_actions_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_triage_classification_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/patient_details_controller.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_photo_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_details/widgets/details_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_actions_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_description_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_map_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_personal_data_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_triage_classification_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/patient_record_app_bar_widget.dart';

// Cascarón de detalle de paciente (paramédico). Solo layout y datos inyectados
class PatientDetailsPage extends StatelessWidget {
  const PatientDetailsPage({
    super.key,
    required this.shellMode,
    this.errorMessage,
    this.appBar,
    this.stickyActionBar,
    required this.bodyChildren,
    this.bottomPadding = 24,
  });

  final PatientDetailsShellMode shellMode;
  final String? errorMessage;
  final PreferredSizeWidget? appBar;
  final Widget? stickyActionBar;
  final List<Widget> bodyChildren;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    switch (shellMode) {
      case PatientDetailsShellMode.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case PatientDetailsShellMode.error:
        return Scaffold(
          appBar: AppBar(title: const Text('Paciente')),
          body: Center(child: Text(errorMessage ?? 'Error')),
        );
      case PatientDetailsShellMode.notFound:
        return Scaffold(
          appBar: AppBar(title: const Text('Paciente')),
          body: const Center(child: Text('Paciente no encontrado.')),
        );
      case PatientDetailsShellMode.ready:
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: appBar,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...bodyChildren,
                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
              if (stickyActionBar != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: stickyActionBar,
                ),
            ],
          ),
        );
    }
  }

  static Widget infoSection(String title, String body) {
    if (body.trim().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  static Widget exportRouteButton({required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.directions, color: Color(0xFFCE1125)),
        label: const Text('Exportar ruta hacia el hospital'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFCE1125),
          side: const BorderSide(color: Color(0xFFCE1125)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  static PreferredSizeWidget readyAppBar({
    required TriageCategory triageCategory,
    required VoidCallback onBackTap,
    required VoidCallback onClosePatientTap,
  }) {
    return PatientRecordAppBarWidget(
      data: PatientRecordAppBarData(
        triageCategory: triageCategory,
        backLabel: 'Regresar al incidente',
        onBackTap: onBackTap,
        actionLabel: 'Cerrar paciente',
        onActionTap: onClosePatientTap,
      ),
    );
  }

  static Widget readyBottomBar({
    required bool savingEdit,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return PatientActionsWidget(
      data: PatientActionsData(
        onCancelTap: savingEdit ? () {} : onCancel,
        onConfirmTap: savingEdit ? () {} : onConfirm,
      ),
    );
  }

  static List<Widget> readyBody({
    required DetailsHeaderData headerData,
    required DetailsStatusData statusData,
    required DetailsPhotoData photoData,
    required PatientTriageClassificationData triageData,
    required PatientMapData mapData,
    required PatientPersonalData personalData,
    required PatientDescriptionData descriptionData,
    List<Widget> extraSections = const [],
    Widget? trailing,
  }) {
    return [
      DetailsHeaderWidget(data: headerData),
      Transform.translate(
        offset: const Offset(0, -15),
        child: DetailsStatusStripWidget(data: statusData),
      ),
      DetailsPhotoWidget(data: photoData),
      const SizedBox(height: 20),
      PatientTriageClassificationWidget(data: triageData),
      const SizedBox(height: 20),
      PatientMapWidget(data: mapData),
      const SizedBox(height: 20),
      PatientPersonalDataWidget(data: personalData),
      const SizedBox(height: 20),
      PatientDescriptionWidget(data: descriptionData),
      ...extraSections,
      ?trailing,
    ];
  }
}
