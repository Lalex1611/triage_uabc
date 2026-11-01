import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/core/theme/triage_tone.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Aviso del rediseño (Figma "TRIAGE/Aviso"): recuadro con ícono, título y
/// explicación opcional, dentro de la pantalla
///
/// [tone] fija color e ícono (ver [TriageTone]). Ocupa el ancho que le den y
/// crece en alto con el texto. Si aparece después de cargar la pantalla
/// (p. ej. un error al guardar), el lector de pantalla lo anuncia solo.
class TriageAlert extends StatelessWidget {
  const TriageAlert({
    super.key,
    required this.tone,
    required this.title,
    this.message,
  });

  final TriageTone tone;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(TriageSpacing.lg),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(TriageRadii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TriageIcon(tone.icon, size: TriageSizes.icon, color: tone.color),
            const SizedBox(width: TriageSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TriageTextStyles.labelMedium.copyWith(
                      color: tone.color,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: TriageSpacing.xxs),
                    Text(
                      message,
                      style: TriageTextStyles.bodySmall.copyWith(
                        color: TriageColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
