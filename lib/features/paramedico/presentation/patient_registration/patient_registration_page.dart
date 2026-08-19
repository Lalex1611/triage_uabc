import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_record_app_bar_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_actions_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_description_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_map_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_personal_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_photo_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_triage_classification_data.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_actions_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_description_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_header_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_map_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_personal_data_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_photo_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/patient_registration/widgets/patient_triage_classification_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/patient_record_app_bar_widget.dart';

// Cascarón de registro de paciente (paramédico). Solo layout y callbacks
class PatientRegistrationPage extends StatelessWidget {
  const PatientRegistrationPage({
    super.key,
    required this.appBarData,
    required this.actionsData,
    required this.headerData,
    required this.photoData,
    required this.triageData,
    required this.mapSectionKey,
    required this.mapData,
    required this.personalData,
    required this.descriptionData,
  });

  final PatientRecordAppBarData appBarData;
  final PatientActionsData actionsData;
  final PatientHeaderData headerData;
  final PatientPhotoData photoData;
  final PatientTriageClassificationData triageData;
  final Key mapSectionKey;
  final PatientMapData mapData;
  final PatientPersonalData personalData;
  final PatientDescriptionData descriptionData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PatientRecordAppBarWidget(data: appBarData),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                PatientHeaderWidget(data: headerData),
                const SizedBox(height: 12),
                PatientPhotoWidget(data: photoData),
                const SizedBox(height: 20),
                PatientTriageClassificationWidget(data: triageData),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: mapSectionKey,
                  child: PatientMapWidget(data: mapData),
                ),
                const SizedBox(height: 20),
                PatientPersonalDataWidget(data: personalData),
                const SizedBox(height: 20),
                PatientDescriptionWidget(data: descriptionData),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PatientActionsWidget(data: actionsData),
          ),
        ],
      ),
    );
  }
}
