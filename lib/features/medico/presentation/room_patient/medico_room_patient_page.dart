import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_triage_level.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_attention_note.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_discharge_info.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/medico_incoming_review_format.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_reported_state_widget.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/medico_room_format.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_room_bottom_bar_widget.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_room_notes_widget.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_room_photos_history_widget.dart';
import 'package:sistema_triage/features/medico/presentation/room_patient/widgets/medico_room_triage_card_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Paciente en sala (mockup 06): nivel de triage hospitalario, origen y datos,
/// fotografías e historial, notas de atención y, al final, el estado reportado
/// por el paramédico o el motivo de consulta si llegó por su cuenta. Abajo,
/// "Agregar nota de atención" y "Dar alta médica" (mockup 10).
/// Sin lógica de negocio.
class MedicoRoomPatientPage extends StatelessWidget {
  const MedicoRoomPatientPage({
    super.key,
    required this.summary,
    required this.discharged,
    required this.photos,
    required this.history,
    this.notes = const [],
    this.discharge,
    required this.onBackTap,
    required this.onEditPatientTap,
    required this.onShowQrTap,
    this.receivedAt,
    this.dischargedAt,
    this.consultationCode,
    this.onAddPhotoTap,
    this.onAddNoteTap,
    this.onDischargeTap,
    this.busy = false,
    this.now,
  });

  final MedicoIncomingReview summary;
  final bool discharged;
  final DateTime? receivedAt;
  final DateTime? dischargedAt;
  final String? consultationCode;
  final List<String> photos;
  final List<MedicoRoomHistoryItem> history;
  final List<MedicoAttentionNote> notes;

  /// Alta registrada (solo pacientes dados de alta)
  final MedicoDischargeInfo? discharge;

  final VoidCallback onBackTap;
  final VoidCallback onEditPatientTap;
  final VoidCallback onShowQrTap;
  final VoidCallback? onAddPhotoTap;
  final VoidCallback? onAddNoteTap;
  final VoidCallback? onDischargeTap;
  final bool busy;

  /// Para pruebas; por defecto la hora actual
  final DateTime? now;

  /// Vino en ambulancia (tiene incidente o unidad); si no, llegó por su cuenta
  bool get _cameByAmbulance =>
      summary.incidentId != null || summary.unitCode != null;

  /// Al final, como apoyo para el médico: lo que reportó el paramédico o, si
  /// llegó por su cuenta, el motivo de consulta del registro
  Widget _supportCard() {
    final r = summary;
    if (_cameByAmbulance) {
      return MedicoReviewCard(
        title: 'Estado reportado',
        child: MedicoReviewReportedState(
          injuries: r.injuryLabels,
          description: r.reportedDescription,
          startTriageMode: r.startTriageModeLabel,
        ),
      );
    }
    final reason = r.reportedDescription;
    return MedicoReviewCard(
      title: 'Motivo de consulta',
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          reason ?? 'No se registró motivo de consulta.',
          style: TextStyle(
            fontSize: reason == null ? 13 : 14,
            height: 1.4,
            color: reason == null
                ? const Color(0xFF8A949E)
                : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }

  /// Tarjeta "Alta médica" del paciente dado de alta: destino, nota y quién
  Widget _dischargeCard(MedicoDischargeInfo info, DateTime now) {
    final rows = <(String, String)>[
      ('Destino', info.destination?.title ?? '—'),
      if (info.dischargedByName != null)
        ('Dio el alta', info.dischargedByName!),
      if (info.createdAt != null)
        ('Fecha', MedicoRoomFormat.historyTime(info.createdAt!, now)),
    ];
    return MedicoReviewCard(
      title: 'Alta médica',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicoReviewRows(rows: rows),
          if (info.note != null) ...[
            const Divider(height: 1, color: Color(0xFFEDF1F4)),
            const SizedBox(height: 12),
            const Text(
              'Nota de alta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C6670),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.note!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<(String, String)> _originRows() {
    final r = summary;
    final cameByAmbulance = _cameByAmbulance;
    return [
      (
        'Llegó',
        cameByAmbulance
            ? (r.unitCode == null
                  ? 'En ambulancia'
                  : 'En ambulancia ${r.unitCode}')
            : 'Por su cuenta',
      ),
      if (r.incidentId != null)
        ('Incidente', MedicoIncomingReviewFormat.incidentLabel(r)!),
      if (r.paramedicName != null) ('Paramédico', r.paramedicName!),
      ('Edad', r.ageYears == null ? '—' : '${r.ageYears} años'),
      ('Seguro', r.insuranceLabel ?? '—'),
      ('Código de consulta', consultationCode ?? '—'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = summary;
    final level = MedicoTriageLevel.levelOf(r.triage);
    final overline = level == null
        ? 'TRIAGE HOSPITALARIO'
        : 'TRIAGE HOSPITALARIO · NIVEL $level';
    final title =
        '${MedicoRoomFormat.colorName(r.triage.label.toLowerCase())} · '
        '${MedicoRoomFormat.levelName(r.triage)}';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: MedicoReviewHeader(
              title: IncidentPresentationFormatters.shortPatientId(r.patientId),
              subtitle:
                  '${r.displayName} · ${discharged ? 'dado de alta' : 'en sala'}',
              onBackTap: onBackTap,
              trailing: PopupMenuButton<String>(
                tooltip: 'Más opciones',
                icon: const Icon(Icons.more_horiz, color: Color(0xFF1A1A1A)),
                onSelected: (v) {
                  if (v == 'qr') onShowQrTap();
                  if (v == 'edit') onEditPatientTap();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'qr',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.qr_code_2_rounded),
                      title: Text('Mostrar QR'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar paciente'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                MedicoRoomTriageCard(
                  color: MedicoTriageLevel.colorOf(r.triage),
                  darkText: r.triage == TriageCategory.amarillo,
                  overline: overline,
                  title: title,
                  subtitle: MedicoRoomFormat.stayLine(
                    discharged: discharged,
                    receivedAt: receivedAt,
                    dischargedAt: dischargedAt,
                    now: now ?? DateTime.now(),
                  ),
                ),
                if (discharged && discharge != null) ...[
                  const SizedBox(height: 16),
                  _dischargeCard(discharge!, now ?? DateTime.now()),
                ],
                const SizedBox(height: 16),
                MedicoReviewCard(
                  title: 'Origen y datos',
                  child: MedicoReviewRows(rows: _originRows()),
                ),
                const SizedBox(height: 16),
                MedicoRoomPhotosHistory(
                  photos: photos,
                  history: history,
                  onAddTap: busy ? null : onAddPhotoTap,
                ),
                const SizedBox(height: 16),
                MedicoRoomNotes(notes: notes, now: now ?? DateTime.now()),
                const SizedBox(height: 16),
                _supportCard(),
              ],
            ),
          ),
          MedicoRoomBottomBar(
            busy: busy,
            onAddNoteTap: onAddNoteTap,
            onDischargeTap: onDischargeTap,
          ),
        ],
      ),
    );
  }
}
