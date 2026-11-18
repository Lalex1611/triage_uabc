import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/features/medico/domain/entities/room_patient/medico_attention_note.dart';

/// Pop-up "Nota de atención" (paciente en sala): cuadro de texto, "Cancelar"
/// a la izquierda, "Agregar nota de atención" en verde a la derecha y una X
/// para cerrar. Al confirmar ejecuta [onSave]; si termina bien se cierra con
/// `true`.
class MedicoAttentionNoteDialog extends StatefulWidget {
  const MedicoAttentionNoteDialog({super.key, required this.onSave});

  final Future<void> Function(String body) onSave;

  static Future<bool> show(
    BuildContext context, {
    required Future<void> Function(String body) onSave,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MedicoAttentionNoteDialog(onSave: onSave),
    );
    return ok == true;
  }

  @override
  State<MedicoAttentionNoteDialog> createState() =>
      _MedicoAttentionNoteDialogState();
}

class _MedicoAttentionNoteDialogState extends State<MedicoAttentionNoteDialog> {
  static const _green = Color(0xFF1E9E52);
  static const _primary = Color(0xFF1C69AA);

  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _close() {
    if (!_busy) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    if (_text.text.trim().isEmpty) {
      setState(() => _error = 'Escribe la nota antes de agregarla.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(_text.text);
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonText = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return PopScope(
      canPop: !_busy,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nota de atención',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : _close,
                      icon: const Icon(Icons.close),
                      color: const Color(0xFF1A1A1A),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextField(
                    controller: _text,
                    enabled: !_busy,
                    autofocus: true,
                    minLines: 6,
                    maxLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        MedicoAttentionNote.maxLength,
                      ),
                    ],
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    decoration: InputDecoration(
                      hintText:
                          'Escribe la evolución, indicaciones o hallazgos '
                          'del paciente',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA3ADB8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(12),
                      border: border(const Color(0xFFD3DBE3)),
                      enabledBorder: border(const Color(0xFFD3DBE3)),
                      focusedBorder: border(_primary, 1.4),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _busy ? null : _close,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A1A1A),
                              side: const BorderSide(color: Color(0xFFD3DBE3)),
                              shape: shape,
                              textStyle: buttonText,
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: _busy ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                              disabledBackgroundColor: _green.withValues(
                                alpha: 0.6,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              shape: shape,
                              textStyle: buttonText,
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Agregar nota de atención'),
                                  ),
                          ),
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
