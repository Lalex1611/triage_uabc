import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/services/paramedico_catalog_mappers.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Pestaña Resumen del incidente (B10). [patients] son todos los del incidente,
/// sin los filtros de la pestaña Pacientes
class IncidentDetailsStatsTab extends StatelessWidget {
  final List<ParamedicoPatientRow> patients;

  const IncidentDetailsStatsTab({super.key, required this.patients});

  int _withStatus(PatientLifecycleStatus status) => patients
      .where(
        (p) =>
            (PatientLifecycleStatus.fromDb(p.status) ??
                PatientLifecycleStatus.waiting) ==
            status,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    // Misma fuente que el conteo del encabezado, para que siempre coincidan
    final counts = ParamedicoCatalogMappers.triageCountsFor(patients);
    final progress = [
      ('Registrados', patients.length),
      ('En espera', _withStatus(PatientLifecycleStatus.waiting)),
      ('Trasladando', _withStatus(PatientLifecycleStatus.transferring)),
      ('Recibidos en hospital', _withStatus(PatientLifecycleStatus.received)),
      ('Alta médica', _withStatus(PatientLifecycleStatus.discharged)),
      ('Rechazados', patients.where((p) => p.wasRejected).length),
    ];
    final hospitals = <String, int>{};
    for (final patient in patients) {
      final name = patient.hospitalName;
      if (name != null) hospitals[name] = (hospitals[name] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: TriageSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TriageSpacing.lg,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TriageSpacing.sm,
            children: [
              _MetricPair(
                TriageMetric.level(
                  TriageLevel.red,
                  value: '${counts.red}',
                  label: 'Inmediatos',
                ),
                TriageMetric.level(
                  TriageLevel.yellow,
                  value: '${counts.yellow}',
                  label: 'Urgentes',
                ),
              ),
              _MetricPair(
                TriageMetric.level(
                  TriageLevel.green,
                  value: '${counts.green}',
                  label: 'Leves',
                ),
                TriageMetric.level(
                  TriageLevel.black,
                  value: '${counts.black}',
                  label: 'Fallecidos',
                ),
              ),
            ],
          ),
          TriageSectionCard(
            title: 'Avance del traslado',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, (label, count)) in progress.indexed) ...[
                  if (index > 0)
                    const Divider(
                      height: TriageSizes.hairline,
                      thickness: TriageSizes.hairline,
                      color: TriageColors.borderSubtle,
                    ),
                  TriageDataRow(label: label, value: '$count'),
                ],
              ],
            ),
          ),
          if (hospitals.isNotEmpty)
            TriageSectionCard(
              title: 'Hospitales destino',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: TriageSpacing.md,
                children: [
                  for (final MapEntry(key: name, value: count)
                      in hospitals.entries)
                    _HospitalRow(name: name, patientCount: count),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricPair extends StatelessWidget {
  const _MetricPair(this.first, this.second);

  final TriageMetric first;
  final TriageMetric second;

  @override
  Widget build(BuildContext context) {
    // Mismo alto en las dos si una pasa a otra línea con texto grande
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TriageSpacing.sm,
        children: [
          Expanded(child: first),
          Expanded(child: second),
        ],
      ),
    );
  }
}

class _HospitalRow extends StatelessWidget {
  const _HospitalRow({required this.name, required this.patientCount});

  final String name;
  final int patientCount;

  static const double _symbolSize = 38;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        spacing: TriageSpacing.md,
        children: [
          SizedBox.square(
            dimension: context.rDim(_symbolSize),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TriageColors.hospitalSoft,
                borderRadius: BorderRadius.circular(TriageRadii.md),
              ),
              child: const Center(
                child: TriageIcon(
                  TriageIcons.hospital,
                  size: TriageSizes.icon,
                  color: TriageColors.hospitalAccent,
                ),
              ),
            ),
          ),
          Expanded(
            child: TriageOptionText(
              title: name,
              detail: patientCount == 1
                  ? '1 paciente'
                  : '$patientCount pacientes',
              titleStyle: TriageTextStyles.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
