import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_triage_filter.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/incident_metadata_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_card_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_list_header_data.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/incident_details/patient_triage_filters_data.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';

/// Convierte datos del repositorio a datos de la vista
class IncidentDetailsViewMapper {
  IncidentDetailsViewMapper._();

  static IncidentHeaderData headerData({
    required ParamedicoIncidentSummary incident,
    required List<ParamedicoPatientRow> patients,
    required bool isEditable,
    required VoidCallback? onShowMapTap,
    required VoidCallback? onEditLocationTap,
    required VoidCallback? onEditTitleTap,
  }) {
    final counts = ParamedicoCatalogMappers.triageCountsFor(patients);
    final coords = IncidentPresentationFormatters.incidentMapCoords(incident);
    final hasGps = IncidentPresentationFormatters.hasIncidentLocation(incident);

    return IncidentHeaderData(
      id: IncidentPresentationFormatters.shortIncidentId(incident.id),
      createdAtLabel: IncidentPresentationFormatters.formatIncidentExactDate(
        incident.createdAt,
      ),
      title: incident.generatedTitle,
      latitude: coords.$1,
      longitude: coords.$2,
      gpsCoordinates: IncidentPresentationFormatters.incidentGpsLabel(incident),
      hasGps: hasGps,
      redCount: counts.red,
      yellowCount: counts.yellow,
      greenCount: counts.green,
      blackCount: counts.black,
      totalPatients: counts.total,
      isEditable: isEditable,
      onShowMapTap: hasGps ? onShowMapTap : null,
      onEditLocationTap: isEditable ? onEditLocationTap : null,
      onEditTitleTap: isEditable ? onEditTitleTap : null,
    );
  }

  static IncidentMetadataData metadataData({
    required String? creatorName,
    required ParamedicoIncidentSummary incident,
  }) {
    return IncidentMetadataData(
      creatorName: creatorName ?? '—',
      timeElapsedLabel: IncidentPresentationFormatters.relativeCreated(
        incident.createdAt,
      ),
    );
  }

  static PatientListHeaderData listHeaderData({
    required int patientCount,
    required PatientSortOption sortOption,
    required ValueChanged<PatientSortOption> onSortChanged,
  }) {
    return PatientListHeaderData(
      patientCount: patientCount,
      sortOption: sortOption,
      onSortChanged: onSortChanged,
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
    required String coordinatesLabel,
    required void Function(String patientId) onPatientTap,
  }) {
    return filtered.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      return PatientCardData(
        id: IncidentPresentationFormatters.shortPatientId(p.id),
        number: i + 1,
        triageCategory: ParamedicoCatalogMappers.triageFromDb(p.triageColor),
        name: p.displayName,
        dateStr: IncidentPresentationFormatters.formatDateTime(p.createdAt),
        coordinates: coordinatesLabel == '—' ? '—' : coordinatesLabel,
        status: ParamedicoCatalogMappers.statusFromDb(p.status),
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
