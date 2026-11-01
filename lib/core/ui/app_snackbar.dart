import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tone.dart';
import 'package:sistema_triage/shared/widgets/triage_toast_widget.dart';

/// Aviso breve de la app con el estilo del rediseño ([showTriageToast])
///
/// Se mantiene esta firma para no tocar las llamadas existentes: [isError]
/// usa el tono de peligro y, si no, el informativo. El código nuevo puede
/// llamar a [showTriageToast] para elegir otro tono o añadir una acción.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) => showTriageToast(
  context,
  message,
  tone: isError ? TriageTone.danger : TriageTone.info,
  duration: duration,
);
