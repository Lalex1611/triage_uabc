import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_details_app_bar_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_details/medico_triage_history_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_actions_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_description_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_extra_data_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_header_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_personal_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_photo_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_status_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_triage_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/register_patient/medico_register_vital_signs_data.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/medico_patient_details_page.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/widgets/medico_details_app_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_details/widgets/medico_triage_history_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_actions_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_description_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_extra_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_personal_data_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_photo_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_status_dropdown_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_triage_widget.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/widgets/medico_register_vital_signs_widget.dart';
import 'package:sistema_triage/features/medico/presentation/routing/medico_patient_details_controller.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Vista de detalle del expediente médico del paciente
class MedicoPatientDetailsFlowPage extends StatefulWidget {
  const MedicoPatientDetailsFlowPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<MedicoPatientDetailsFlowPage> createState() =>
      _MedicoPatientDetailsFlowPageState();
}

class _MedicoPatientDetailsFlowPageState
    extends State<MedicoPatientDetailsFlowPage> {
  late final MedicoPatientDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MedicoPatientDetailsController(patientId: widget.patientId);
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
    final c = _controller;
    final mode = c.shellMode;

    if (mode != MedicoPatientDetailsShellMode.ready) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text('Detalle del paciente'),
        ),
        body: Center(
          child: switch (mode) {
            MedicoPatientDetailsShellMode.loading =>
              const CircularProgressIndicator(),
            MedicoPatientDetailsShellMode.notFound => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Paciente no encontrado.'),
            ),
            _ => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(c.errorMessage ?? 'Error'),
            ),
          },
        ),
      );
    }

    final d = c.detail!;
    final demo = d.demographics;
    final displayName = d.displayName;
    final patientIdShort = IncidentPresentationFormatters.shortPatientId(d.id);
    final dt = IncidentPresentationFormatters.formatDateTime(d.createdAt);

    Widget? bottomActions;
    if (c.showAcceptReject) {
      final busy = c.actionBusy;
      bottomActions = MedicoRegisterActionsWidget(
        data: MedicoRegisterActionsData(
          cancelLabel: 'CANCELAR',
          confirmLabel: 'CONFIRMAR CAMBIO',
          onCancelTap: busy ? () {} : () => unawaited(c.onRejectFlow(context)),
          onConfirmTap: busy ? () {} : () => unawaited(c.onAccept(context)),
        ),
      );
    } else if (c.showSaveBar) {
      final busy = c.savingClinical;
      bottomActions = MedicoRegisterActionsWidget(
        data: MedicoRegisterActionsData(
          cancelLabel: 'CANCELAR',
          confirmLabel: busy ? 'GUARDANDO…' : 'GUARDAR',
          onCancelTap: busy ? () {} : () => c.cancelClinicalSession(),
          onConfirmTap: busy ? () {} : () => unawaited(c.saveClinical(context)),
        ),
      );
    }

    return MedicoPatientDetailsPage(
      appBar: MedicoDetailsAppBarWidget(
        data: MedicoDetailsAppBarData(onBackTap: () => c.onBack(context)),
      ),
      bottomActions: bottomActions,
      bodyChildren: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            MedicoRegisterHeaderWidget(
              data: MedicoRegisterHeaderData(
                patientId: patientIdShort,
                patientName: c.clinicalLayoutUnlocked
                    ? c.editName
                    : displayName,
                registrationDateTime: dt,
                showAsterisk: false,
                isReadOnly: !c.clinicalLayoutUnlocked,
                onNameChanged: c.setEditName,
                onEditNameTap: () => c.toggleClinicalPrivileges(context),
                onEditDateTap: () {},
                onGenerateQrTap: () =>
                    unawaited(c.onShowConsultationQr(context)),
                qrButtonLabel: 'Ver Código\nde Consulta',
              ),
            ),
            Positioned(
              right: 20,
              bottom: -16,
              child: MedicoRegisterStatusDropdownWidget(
                data: MedicoRegisterStatusData(
                  currentStatus: c.medicoLifecycleUi(),
                  canEdit:
                      c.clinicalLayoutUnlocked &&
                      c.allowsClinicalEdit &&
                      !c.lifecycleStatusSaving,
                  onStatusChanged: (s) =>
                      unawaited(c.applyLifecycleStatusPick(context, s)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        MedicoRegisterPhotoWidget(
          data: MedicoRegisterPhotoData(
            photos: c.photosForToolbar(),
            isReadOnly: !c.clinicalLayoutUnlocked,
            onCameraTap: () =>
                unawaited(c.pickPatientPhoto(ImageSource.camera)),
            onAddImageTap: () =>
                unawaited(c.pickPatientPhoto(ImageSource.gallery)),
            onRemovePhotoTap: c.removePhotoAt,
          ),
        ),
        const SizedBox(height: 24),
        MedicoRegisterTriageWidget(
          data: MedicoRegisterTriageData(
            selectedCategory: c.editTriageSel ?? c.triageUi(),
            isEditingEnabled: c.triageBoxesEnabled(),
            title: 'Triage hospitalario',
            onEditTap: null,
            onCategorySelected: c.onTriageCategorySelected,
          ),
        ),
        const SizedBox(height: 26),
        MedicoRegisterPersonalDataWidget(
          data: MedicoRegisterPersonalData(
            birthDay: c.birthDayField(demo),
            birthMonth: c.birthMonthField(demo),
            birthYear: c.birthYearField(demo),
            gender: c.genderField(demo),
            contactNumber: () {
              final x = c.contactField(demo).trim();
              return x.isEmpty ? null : x;
            }(),
            insurance: c.insuranceField(demo),
            isReadOnly: c.personalSectionReadOnly(),
            onEditTap: c.clinicalLayoutUnlocked
                ? c.togglePersonalSubEdit
                : null,
            onDayChanged: c.setEditBirthDay,
            onMonthChanged: c.setEditBirthMonth,
            onYearChanged: c.setEditBirthYear,
            onGenderChanged: c.setEditGender,
            onContactNumberChanged: c.setEditContact,
            onInsuranceChanged: c.setEditInsurance,
          ),
        ),
        const SizedBox(height: 22),
        MedicoRegisterDescriptionWidget(
          data: MedicoRegisterDescriptionData(
            descriptionText: c.descriptionUi(demo),
            isReadOnly: !c.clinicalLayoutUnlocked,
            onDescriptionChanged: c.setEditDescription,
          ),
        ),
        const SizedBox(height: 26),
        MedicoRegisterVitalSignsWidget(
          data: MedicoRegisterVitalSignsData(
            systolicPressure: c.systolic(demo),
            diastolicPressure: c.diastolic(demo),
            heartRate: c.heart(demo),
            respiratoryRate: c.respiratory(demo),
            temperature: c.temperature(demo),
            oxygenSaturation: c.oxygen(demo),
            glucose: c.glucose(demo),
            isReadOnly: !c.clinicalLayoutUnlocked,
            onSystolicPressureChanged: c.setEditSystolic,
            onDiastolicPressureChanged: c.setEditDiastolic,
            onHeartRateChanged: c.setEditHeart,
            onRespiratoryRateChanged: c.setEditRespiratory,
            onTemperatureChanged: c.setEditTemperature,
            onOxygenSaturationChanged: c.setEditOxygen,
            onGlucoseChanged: c.setEditGlucose,
          ),
        ),
        const SizedBox(height: 22),
        MedicoRegisterExtraDataWidget(
          data: MedicoRegisterExtraDataData(
            allergies: c.allergies(demo),
            medications: c.medications(demo),
            medicalHistory: c.medicalHistory(demo),
            isReadOnly: !c.clinicalLayoutUnlocked,
            onAllergiesChanged: c.setEditAllergies,
            onMedicationsChanged: c.setEditMedications,
            onMedicalHistoryChanged: c.setEditMedicalHistory,
          ),
        ),
        const SizedBox(height: 26),
        MedicoTriageHistoryWidget(
          data: MedicoTriageHistoryData(
            entries: c.triageHistory,
          ),
        ),
        if (c.assignedHospital != null &&
            (c.assignedHospital!.name).isNotEmpty) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital destino',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  c.assignedHospital!.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 48),
        if (!c.allowsClinicalEdit && !c.showAcceptReject) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Text(
              'Cuando el paciente esté en traslado, confirme o cancele el ingreso '
              'desde el listado de Inicio o con «Confirmar cambio» / «Cancelar» en '
              'este detalle. Después del ingreso (Recibido), use el ícono de edición '
              'junto al nombre para modificar el expediente.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }
}
