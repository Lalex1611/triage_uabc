import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/medico_incoming_review_format.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/widgets/medico_transfer_bottom_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Paciente aceptado (mockup 11): confirma la recepción y resume estado,
/// nivel, llegada y código. Se cierra con `true` para "Ver en la sala" y con
/// `false` para "Volver a entrantes" o la X.
class MedicoTransferAcceptedPage extends StatelessWidget {
  const MedicoTransferAcceptedPage({
    super.key,
    required this.review,
    this.consultationCode,
    this.now,
  });

  final MedicoIncomingReview review;
  final String? consultationCode;

  /// Para pruebas; por defecto la hora actual
  final DateTime? now;

  static const _primary = Color(0xFF1C69AA);
  static const _green = Color(0xFF1E9E52);

  @override
  Widget build(BuildContext context) {
    final r = review;
    final t = now ?? DateTime.now();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F6),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: MedicoReviewHeader(
                title: 'Paciente aceptado',
                subtitle:
                    '${IncidentPresentationFormatters.shortPatientId(r.patientId)} · ${r.displayName}',
                leadingIcon: Icons.close,
                onBackTap: () => Navigator.of(context).pop(false),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDEFE0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 44,
                        color: _green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recepción confirmada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    // El aviso al paramédico lo genera el backend al pasar a
                    // "recibido" (migración 20261117170000)
                    child: Text(
                      '${r.paramedicName ?? 'El paramédico'} ya recibió el '
                      'aviso. ${r.displayName} aparece en la sala en cuanto '
                      'llegue a urgencias.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF5C6670),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE1E7ED)),
                    ),
                    child: MedicoReviewRows(
                      rows: [
                        ('Estado', 'Recibido'),
                        (
                          'Nivel',
                          MedicoIncomingReviewFormat.levelSentence(r.triage),
                        ),
                        (
                          'Llegada estimada',
                          MedicoIncomingReviewFormat.arrivalShort(r, t),
                        ),
                        ('Código de consulta', consultationCode ?? '—'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            MedicoTransferBottomBar(
              primaryLabel: 'Ver en la sala',
              primaryColor: _primary,
              onPrimaryTap: () => Navigator.of(context).pop(true),
              cancelLabel: 'Volver a entrantes',
              onCancelTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
