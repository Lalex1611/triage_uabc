import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Convierte datos del repositorio a datos de la vista
class IncidentDetailsViewMapper {
  IncidentDetailsViewMapper._();

  static IncidentHeaderData headerData({
    required ParamedicoIncidentSummary incident,
    required List<ParamedicoPatientRow> patients,
    required String? creatorName,
  }) {
    final counts = ParamedicoCatalogMappers.triageCountsFor(patients);

    return IncidentHeaderData(
      id: IncidentPresentationFormatters.shortIncidentId(incident.id),
      title: EmergencyCatalog.nameFor(incident.emergencyType),
      gpsCoordinates: IncidentPresentationFormatters.incidentGpsLabel(incident),
      authorLine: [
        ?creatorName,
        IncidentPresentationFormatters.relativeCreated(
          incident.createdAt,
        ).toLowerCase(),
        IncidentPresentationFormatters.formatTime(incident.createdAt),
      ].join(' · '),
      isClosed: incident.status == 'cerrado',
      redCount: counts.red,
      yellowCount: counts.yellow,
      greenCount: counts.green,
      blackCount: counts.black,
      totalPatients: counts.total,
    );
  }

  static PatientTriageFiltersData triageFiltersData({
    required PatientTriageFilter activeFilter,
    required ValueChanged<PatientTriageFilter> onFilterChanged,
  }) {
    return PatientTriageFiltersData(
      activeFilter: activeFilter,
      onFilterChanged: onFilterChanged,
    );
  }

  static List<PatientCardData> patientCards({
    required List<ParamedicoPatientRow> filtered,
    required void Function(String patientId) onPatientTap,
  }) {
    return filtered.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      return PatientCardData(
        id: IncidentPresentationFormatters.shortPatientId(p.id),
        number: i + 1,
        triageLevel: TriageLevel.fromDb(p.triageColor) ?? TriageLevel.green,
        name: p.displayName,
        dateStr: IncidentPresentationFormatters.formatTime(p.createdAt),
        note: p.note,
        status:
            PatientLifecycleStatus.fromDb(p.status) ??
            PatientLifecycleStatus.waiting,
        onCardTap: () => onPatientTap(p.id),
      );
    }).toList();
  }

  static String listEmptyMessage({
    required List<ParamedicoPatientRow> allPatients,
    required List<ParamedicoPatientRow> filtered,
  }) {
    if (allPatients.isEmpty) {
      return 'Aún no hay pacientes en este incidente.\nUse «Registrar paciente» para añadir uno.';
    }
    if (filtered.isEmpty) {
      return 'No hay pacientes con ese criterio de búsqueda o filtro.';
    }
    return '';
  }
}
