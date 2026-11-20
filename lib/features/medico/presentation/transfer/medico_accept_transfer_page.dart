import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/patient_review/medico_incoming_review.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/medico_incoming_review_format.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/widgets/medico_transfer_bottom_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Confirmación de recepción de un traslado (mockup 03). Al confirmar ejecuta
/// [onConfirm]; si termina bien la pantalla se cierra con `true`.
class MedicoAcceptTransferPage extends StatefulWidget {
  const MedicoAcceptTransferPage({
    super.key,
    required this.review,
    required this.onConfirm,
    this.now,
  });

  final MedicoIncomingReview review;

  /// Marca al paciente como recibido; si lanza, se muestra el error
  final Future<void> Function() onConfirm;

  /// Para pruebas; por defecto la hora actual
  final DateTime? now;

  @override
  State<MedicoAcceptTransferPage> createState() =>
      _MedicoAcceptTransferPageState();
}

class _MedicoAcceptTransferPageState extends State<MedicoAcceptTransferPage> {
  static const _primary = Color(0xFF1C69AA);
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final m = RegExp(r'message: ([^,]+)').firstMatch('$e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = m?.group(1)?.trim() ?? '$e'.replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final now = widget.now ?? DateTime.now();

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F6),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: MedicoReviewHeader(
                title: 'Confirmar recepción',
                subtitle:
                    '${IncidentPresentationFormatters.shortPatientId(r.patientId)} · ${r.displayName}',
                leadingIcon: Icons.close,
                onBackTap: () {
                  if (!_busy) Navigator.of(context).pop(false);
                },
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
                        color: Color(0xFFDCE6F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 42,
                        color: _primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Aceptas a este paciente?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Al aceptar, el paciente pasa a "Recibido", se avisa al '
                      'paramédico y entra a la sala hospitalaria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                        ('Paciente', r.displayName),
                        (
                          'Clasificación',
                          MedicoIncomingReviewFormat.levelSentence(r.triage),
                        ),
                        (
                          'Llegada estimada',
                          MedicoIncomingReviewFormat.arrivalShort(r, now),
                        ),
                        ('Origen', MedicoIncomingReviewFormat.originLabel(r)),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            MedicoTransferBottomBar(
              primaryLabel: 'Sí, lo recibimos',
              primaryColor: _primary,
              busy: _busy,
              onPrimaryTap: _confirm,
              onCancelTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
