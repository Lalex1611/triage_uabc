import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Título y línea de detalle de las opciones ([TriageLargeOption],
/// [TriageRadioOption] y [TriageOptionRow])
///
/// Ninguno de los dos textos se corta: pasan a otra línea.
class TriageOptionText extends StatelessWidget {
  const TriageOptionText({
    super.key,
    required this.title,
    required this.detail,
    this.titleStyle = TriageTextStyles.labelLarge,
    this.titleColor = TriageColors.textPrimary,
  });

  final String title;
  final String detail;
  final TextStyle titleStyle;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: TriageSpacing.xxs,
      children: [
        Text(title, style: titleStyle.copyWith(color: titleColor)),
        Text(
          detail,
          style: TriageTextStyles.bodySmall.copyWith(
            color: TriageColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
