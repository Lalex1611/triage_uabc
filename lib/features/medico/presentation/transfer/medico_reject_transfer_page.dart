import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_transfer_reject_reason.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/widgets/medico_transfer_bottom_bar_widget.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_presentation_formatters.dart';

/// Rechazo de un traslado (mockup 04): motivo, comentario opcional y aviso de
/// que el paramédico tendrá que reasignar hospital. Al confirmar ejecuta
/// [onReject] con el texto del motivo; si termina bien se cierra con `true`.
class MedicoRejectTransferPage extends StatefulWidget {
  const MedicoRejectTransferPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onReject,
  });

  final String patientId;
  final String patientName;

  /// Rechaza el traslado con el motivo; si lanza, se muestra el error
  final Future<void> Function(String reason) onReject;

  @override
  State<MedicoRejectTransferPage> createState() =>
      _MedicoRejectTransferPageState();
}

class _MedicoRejectTransferPageState extends State<MedicoRejectTransferPage> {
  static const _red = Color(0xFFC0141C);
  static const _primary = Color(0xFF1C69AA);
  static const _maxComment = 500;

  final _comment = TextEditingController();
  MedicoTransferRejectReason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) {
      setState(() => _error = 'Elige por qué no pueden recibirlo.');
      return;
    }
    if (reason.requiresComment && _comment.text.trim().isEmpty) {
      setState(
        () => _error = 'Escribe el motivo en el comentario para el paramédico.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onReject(reason.reasonText(_comment.text));
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
                title: 'Rechazar traslado',
                subtitle:
                    '${IncidentPresentationFormatters.shortPatientId(widget.patientId)} · ${widget.patientName}',
                leadingIcon: Icons.close,
                onBackTap: () {
                  if (!_busy) Navigator.of(context).pop(false);
                },
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const _WarningBanner(),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Por qué no pueden recibirlo?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final r in MedicoTransferRejectReason.values) ...[
                    _ReasonOption(
                      reason: r,
                      selected: _reason == r,
                      onTap: _busy
                          ? null
                          : () => setState(() {
                              _reason = r;
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _reason?.requiresComment == true
                        ? 'Comentario para el paramédico'
                        : 'Comentario para el paramédico (opcional)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comment,
                    enabled: !_busy,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_maxComment),
                    ],
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Escribe aquí si quieres dar más contexto',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA3ADB8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: _border(const Color(0xFFD3DBE3)),
                      enabledBorder: _border(const Color(0xFFD3DBE3)),
                      focusedBorder: _border(_primary, 1.4),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: _red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            MedicoTransferBottomBar(
              primaryLabel: 'Rechazar traslado',
              primaryColor: _red,
              busy: _busy,
              onPrimaryTap: _submit,
              onCancelTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEFD5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1D9A6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 22, color: Color(0xFFD08A00)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El paramédico tendrá que reasignar hospital',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA86A00),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Se le avisa de inmediato con el motivo que elijas. El '
                  'paciente vuelve a "En espera" para que elija otro hospital.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF6B5A33),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final MedicoTransferRejectReason reason;
  final bool selected;
  final VoidCallback? onTap;

  static const _primary = Color(0xFF1C69AA);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFEAF2FA) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _primary : const Color(0xFFDDE3EA),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 24,
                  color: selected ? _primary : const Color(0xFFA3ADB8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason.subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF5C6670),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
