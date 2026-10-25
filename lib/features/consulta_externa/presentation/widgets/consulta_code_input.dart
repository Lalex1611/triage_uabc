import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_code.dart';

/// Conserva la edicion, seleccion, pegado y semantica de un solo campo nativo.
/// Las seis casillas son su representacion visual, no seis valores separados.
class ConsultaCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final bool hasError;
  final VoidCallback? onRejectedInput;

  const ConsultaCodeInput({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onRejectedInput,
  });

  @override
  State<ConsultaCodeInput> createState() => _ConsultaCodeInputState();
}

class _ConsultaCodeInputState extends State<ConsultaCodeInput> {
  final _focusNode = FocusNode();
  double _pointerX = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final cellWidth =
            (constraints.maxWidth - gap * 5) / ConsultaCode.length;
        final stride = cellWidth + gap;
        final textStyle = AppTextStyles.ESC_Bold_titleSmall.copyWith(
          fontSize: 24,
          height: 1.17,
          color: widget.hasError
              ? const Color(0xFFC30508)
              : const Color(0xFF121924),
        );
        final painter = TextPainter(
          text: TextSpan(text: 'A', style: textStyle),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final height = math.max(62.0, painter.height + 24);
        painter.dispose();

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final activeIndex = value.selection.isValid
                ? value.selection.extentOffset.clamp(0, ConsultaCode.length - 1)
                : 0;
            return Stack(
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: List.generate(ConsultaCode.length, (index) {
                      final focused =
                          _focusNode.hasFocus &&
                          (value.selection.isValid &&
                                  !value.selection.isCollapsed
                              ? index >= value.selection.start &&
                                    index < value.selection.end
                              : index == activeIndex);
                      return Padding(
                        padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
                        child: Container(
                          key: ValueKey('consulta-code-cell-$index'),
                          width: cellWidth,
                          height: height,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: widget.hasError
                                ? const Color(0xFFFDECEC)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: widget.hasError
                                  ? const Color(0xFFC30508)
                                  : focused
                                  ? const Color(0xFF0A7EA4)
                                  : const Color(0xFFD4DCE5),
                              width: focused
                                  ? 2
                                  : widget.hasError
                                  ? 1.5
                                  : 1.25,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              index < value.text.length
                                  ? value.text[index]
                                  : '',
                              style: textStyle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (event) =>
                        _pointerX = event.localPosition.dx,
                    // La seleccion se representa con los bordes de las casillas.
                    // Evita pintar el resaltado nativo sobre dos casillas.
                    child: TextSelectionTheme(
                      data: TextSelectionTheme.of(
                        context,
                      ).copyWith(selectionColor: Colors.transparent),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        textDirection: TextDirection.ltr,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        enableSuggestions: false,
                        showCursor: false,
                        inputFormatters: [
                          _ConsultaCodeFormatter(
                            onRejected: widget.onRejectedInput,
                          ),
                        ],
                        onTap: () {
                          final index = (_pointerX / stride).floor().clamp(
                            0,
                            5,
                          );
                          final offset = math.min(
                            index,
                            widget.controller.text.length,
                          );
                          widget.controller.selection =
                              offset < widget.controller.text.length
                              ? TextSelection(
                                  baseOffset: offset,
                                  extentOffset: offset + 1,
                                )
                              : TextSelection.collapsed(offset: offset);
                        },
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 24,
                          color: Colors.transparent,
                          letterSpacing: stride - 24,
                        ),
                        decoration: const InputDecoration(
                          labelText:
                              'Código de consulta, seis letras o números',
                          labelStyle: TextStyle(color: Colors.transparent),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ConsultaCodeFormatter extends TextInputFormatter {
  final VoidCallback? onRejected;

  _ConsultaCodeFormatter({this.onRejected});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      if (newValue.text.length <= ConsultaCode.length &&
          ConsultaCode.hasValidCharacters(
            ConsultaCode.normalize(newValue.text),
          )) {
        return newValue;
      }
      onRejected?.call();
      return oldValue;
    }
    final normalized = ConsultaCode.normalize(newValue.text);
    if (!ConsultaCode.hasValidCharacters(normalized)) {
      onRejected?.call();
      return oldValue;
    }
    if (normalized.length > ConsultaCode.length) {
      // Un pegado de seis caracteres sustituye el codigo completo incluso si solo
      // habia una casilla seleccionada. Un pegado mayor se rechaza sin recortarlo.
      if (oldValue.selection.isValid) {
        final start = oldValue.selection.start;
        final end = oldValue.selection.end;
        final suffixLength = oldValue.text.length - end;
        final insertedEnd = newValue.text.length - suffixLength;
        if (insertedEnd >= start &&
            newValue.text.startsWith(oldValue.text.substring(0, start)) &&
            newValue.text.endsWith(oldValue.text.substring(end))) {
          final inserted = ConsultaCode.normalize(
            newValue.text.substring(start, insertedEnd),
          );
          if (ConsultaCode.isValid(inserted)) {
            return TextEditingValue(
              text: inserted,
              selection: const TextSelection.collapsed(
                offset: ConsultaCode.length,
              ),
            );
          }
        }
      }
      onRejected?.call();
      return oldValue;
    }
    int offset(int value) => ConsultaCode.normalize(
      newValue.text.substring(0, value.clamp(0, newValue.text.length)),
    ).length;
    return TextEditingValue(
      text: normalized,
      selection: newValue.selection.isValid
          ? TextSelection(
              baseOffset: offset(newValue.selection.baseOffset),
              extentOffset: offset(newValue.selection.extentOffset),
            )
          : TextSelection.collapsed(offset: normalized.length),
    );
  }
}
