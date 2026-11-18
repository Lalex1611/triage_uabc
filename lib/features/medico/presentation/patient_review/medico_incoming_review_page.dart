import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/medico_incoming_review_format.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_actions_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_photos_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_reported_state_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_triage_banner_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Revisión de un paciente que viene en camino (mockup 02): el médico decide
/// si lo recibe o rechaza el traslado. Sin lógica de negocio.
class MedicoIncomingReviewPage extends StatelessWidget {
  const MedicoIncomingReviewPage({
    super.key,
    required this.review,
    required this.onBackTap,
    required this.onAcceptTap,
    required this.onRejectTap,
    this.busy = false,
    this.now,
  });

  final MedicoIncomingReview review;
  final VoidCallback onBackTap;
  final VoidCallback onAcceptTap;
  final VoidCallback onRejectTap;
  final bool busy;

  /// Para pruebas; por defecto la hora actual
  final DateTime? now;

  List<(String, String)> _originRows() {
    final r = review;
    return [
      (
        'Incidente',
        MedicoIncomingReviewFormat.incidentLabel(r) ?? 'Sin incidente',
      ),
      ('Paramédico', r.paramedicName ?? '—'),
      ('Unidad', r.unitCode ?? '—'),
      (
        'Clasificado a las',
        r.classifiedAt == null
            ? '—'
            : MedicoIncomingReviewFormat.hhmm(r.classifiedAt!),
      ),
      ('Folio de regulación', r.regulationFolio ?? '—'),
    ];
  }

  List<(String, String)> _administrativeRows() {
    final r = review;
    return [
      if (r.insuranceLabel != null) ('Seguro médico', r.insuranceLabel!),
      if (r.bloodTypeLabel != null) ('Tipo de sangre', r.bloodTypeLabel!),
      if (r.contactPhone != null) ('Teléfono de contacto', r.contactPhone!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = review;
    final color = MedicoTriageLevel.colorOf(r.triage);
    final title = r.ageYears == null
        ? r.displayName
        : '${r.displayName}, ${r.ageYears} años';
    final admin = _administrativeRows();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: MedicoReviewHeader(
              title: IncidentPresentationFormatters.shortPatientId(r.patientId),
              subtitle: '${r.displayName} · entrante',
              onBackTap: onBackTap,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                MedicoReviewTriageBanner(
                  color: color,
                  darkText: r.triage == TriageCategory.amarillo,
                  levelLabel: MedicoIncomingReviewFormat.levelBanner(r.triage),
                  title: title,
                  arrivalLabel: MedicoIncomingReviewFormat.arrivalLong(
                    r,
                    now ?? DateTime.now(),
                  ),
                ),
                const SizedBox(height: 16),
                MedicoReviewCard(
                  title: 'De dónde viene',
                  child: MedicoReviewRows(rows: _originRows()),
                ),
                const SizedBox(height: 16),
                MedicoReviewCard(
                  title: 'Fotografías del paramédico',
                  child: MedicoReviewPhotos(urls: r.photoUrls),
                ),
                const SizedBox(height: 16),
                MedicoReviewCard(
                  title: 'Estado reportado',
                  child: MedicoReviewReportedState(
                    injuries: r.injuryLabels,
                    description: r.reportedDescription,
                    startTriageMode: r.startTriageModeLabel,
                  ),
                ),
                const SizedBox(height: 16),
                MedicoReviewCard(
                  title: 'Datos administrativos',
                  child: admin.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No se registraron datos administrativos.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8A949E),
                            ),
                          ),
                        )
                      : MedicoReviewRows(rows: admin),
                ),
              ],
            ),
          ),
          MedicoReviewActions(
            busy: busy,
            onRejectTap: onRejectTap,
            onAcceptTap: onAcceptTap,
          ),
        ],
      ),
    );
  }
}
