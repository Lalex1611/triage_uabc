import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/core/theme/triage_tone.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Muestra el aviso breve del rediseño (Figma "TRIAGE/Aviso breve"): mensaje
/// flotante sobre fondo oscuro que se cierra solo
///
/// [tone] fija el ícono (ver [TriageTone]). Con [actionLabel] y [onAction]
/// añade una acción a la derecha (p. ej. "Deshacer"). Es un `SnackBar`, así
/// que el lector de pantalla lo anuncia y, con una acción y la navegación
/// accesible activa, no se cierra solo. Si no hay `ScaffoldMessenger`, no hace
/// nada.
void showTriageToast(
  BuildContext context,
  String message, {
  TriageTone tone = TriageTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  assert(
    (actionLabel == null) == (onAction == null),
    'actionLabel y onAction van juntos',
  );
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: TriageColors.inverse,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TriageRadii.xl),
      ),
      content: Row(
        children: [
          TriageIcon(tone.icon, size: TriageSizes.icon, color: tone.onInverse),
          const SizedBox(width: TriageSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TriageTextStyles.bodyMedium.copyWith(
                color: TriageColors.textInverse,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              onPressed: onAction!,
              textColor: TriageColors.infoOnInverse,
            ),
    ),
  );
}
