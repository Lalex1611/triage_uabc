import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/features/medico/domain/constants/medico_discharge_destination.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_discharge_info.dart';
import 'package:sistema_triage/features/medico/presentation/patient_review/widgets/medico_review_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/transfer/widgets/medico_transfer_bottom_bar_widget.dart';

/// Alta médica (mockup 10): a dónde sale el paciente y nota de alta. Al
/// confirmar ejecuta [onConfirm]; si termina bien se cierra con `true`.
class MedicoDischargePage extends StatefulWidget {
  const MedicoDischargePage({
    super.key,
    required this.folio,
    required this.patientName,
    required this.onConfirm,
  });

  /// "PAC-…"
  final String folio;
  final String patientName;
  final Future<void> Function(
    MedicoDischargeDestination destination,
    String note,
  )
  onConfirm;

  /// Icono de cada destino
  static IconData iconOf(MedicoDischargeDestination d) => switch (d) {
    MedicoDischargeDestination.domicilio => Icons.home_outlined,
    MedicoDischargeDestination.hospitalizacion => Icons.local_hospital_outlined,
    MedicoDischargeDestination.traslado => Icons.local_shipping_outlined,
    MedicoDischargeDestination.defuncion => Icons.close_rounded,
  };

  @override
  State<MedicoDischargePage> createState() => _MedicoDischargePageState();
}

class _MedicoDischargePageState extends State<MedicoDischargePage> {
  static const _green = Color(0xFF1E9E52);
  static const _primary = Color(0xFF1C69AA);

  final _note = TextEditingController();
  MedicoDischargeDestination? _destination;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final d = _destination;
    if (d == null) {
      setState(() => _error = 'Elige a dónde sale el paciente.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm(d, _note.text);
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
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

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
                title: 'Alta médica',
                subtitle: '${widget.folio} · ${widget.patientName}',
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
                  const _InfoBanner(),
                  const SizedBox(height: 20),
                  const Text(
                    '¿A dónde sale el paciente?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final d in MedicoDischargeDestination.values) ...[
                    _DestinationOption(
                      destination: d,
                      selected: _destination == d,
                      onTap: _busy
                          ? null
                          : () => setState(() {
                              _destination = d;
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Nota de alta',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _note,
                    enabled: !_busy,
                    minLines: 4,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        MedicoDischargeInfo.maxNoteLength,
                      ),
                    ],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Indicaciones o resumen de la atención',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA3ADB8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: border(const Color(0xFFD3DBE3)),
                      enabledBorder: border(const Color(0xFFD3DBE3)),
                      focusedBorder: border(_primary, 1.4),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
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
              primaryLabel: 'Confirmar alta médica',
              primaryColor: _green,
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EFF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7DDEE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 21, color: Color(0xFF1C69AA)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El alta cierra el caso',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C69AA),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'El paciente sale de la sala y la consulta externa le '
                  'muestra a la familia que la atención concluyó.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF34506A),
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

class _DestinationOption extends StatelessWidget {
  const _DestinationOption({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final MedicoDischargeDestination destination;
  final bool selected;
  final VoidCallback? onTap;

  static const _green = Color(0xFF1E9E52);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFE6F4EC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _green : const Color(0xFFDDE3EA),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? _green : const Color(0xFFEFF2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    MedicoDischargePage.iconOf(destination),
                    size: 21,
                    color: selected ? Colors.white : const Color(0xFF3F4850),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF5C6670),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_outline_rounded, color: _green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
