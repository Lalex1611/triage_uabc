import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

// Entidad de dominio que transporta la información de un paciente
class MedicoPatientCardData {
  /// Row id from `public.patients.id` (UUID). Empty for mocks / previews
  final String patientRecordId;
  final String id;
  final int number;
  final TriageCategory triageCategory;
  final String name;
  final String dateStr;
  final String coordinates;
  final String eta;
  final String ambulanceUnit;
  final PatientStatus status;

  /// Texto opcional bajo el panel (p. ej. motivo de rechazo de traslado)
  final String? footerNote;
  final bool isRejectedTransfer;
  final VoidCallback? onMapTap;
  final VoidCallback? onCardTap;

  /// Callbacks para el bloque «traslado» (shell con botones debajo de la tarjeta)
  final VoidCallback? onIncomingAcceptTap;
  final VoidCallback? onIncomingRejectTap;

  MedicoPatientCardData({
    this.patientRecordId = '',
    required this.id,
    required this.number,
    required this.triageCategory,
    required this.name,
    required this.dateStr,
    required this.coordinates,
    required this.eta,
    required this.ambulanceUnit,
    required this.status,
    this.footerNote,
    this.isRejectedTransfer = false,
    this.onMapTap,
    this.onCardTap,
    this.onIncomingAcceptTap,
    this.onIncomingRejectTap,
  });

  MedicoPatientCardData copyWith({
    VoidCallback? onCardTap,
    String? footerNote,
    bool? isRejectedTransfer,
  }) {
    return MedicoPatientCardData(
      patientRecordId: patientRecordId,
      id: id,
      number: number,
      triageCategory: triageCategory,
      name: name,
      dateStr: dateStr,
      coordinates: coordinates,
      eta: eta,
      ambulanceUnit: ambulanceUnit,
      status: status,
      footerNote: footerNote ?? this.footerNote,
      isRejectedTransfer: isRejectedTransfer ?? this.isRejectedTransfer,
      onMapTap: onMapTap,
      onCardTap: onCardTap ?? this.onCardTap,
      onIncomingAcceptTap: onIncomingAcceptTap,
      onIncomingRejectTap: onIncomingRejectTap,
    );
  }

  MedicoPatientCardData withoutIncomingCallbacks() {
    return MedicoPatientCardData(
      patientRecordId: patientRecordId,
      id: id,
      number: number,
      triageCategory: triageCategory,
      name: name,
      dateStr: dateStr,
      coordinates: coordinates,
      eta: eta,
      ambulanceUnit: ambulanceUnit,
      status: status,
      footerNote: footerNote,
      isRejectedTransfer: isRejectedTransfer,
      onMapTap: onMapTap,
      onCardTap: onCardTap,
    );
  }

  MedicoPatientCardData withIncomingTransferActions({
    required VoidCallback onAccept,
    required VoidCallback onReject,
    VoidCallback? onTap,
  }) {
    return MedicoPatientCardData(
      patientRecordId: patientRecordId,
      id: id,
      number: number,
      triageCategory: triageCategory,
      name: name,
      dateStr: dateStr,
      coordinates: coordinates,
      eta: eta,
      ambulanceUnit: ambulanceUnit,
      status: status,
      footerNote: footerNote,
      isRejectedTransfer: isRejectedTransfer,
      onMapTap: onMapTap,
      onCardTap: onTap ?? onCardTap,
      onIncomingAcceptTap: onAccept,
      onIncomingRejectTap: onReject,
    );
  }
}
