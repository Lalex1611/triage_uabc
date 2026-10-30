import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/patient_lifecycle_status_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/patient_lifecycle_status.dart';

/// Insignia de estado del rediseño (Figma "TRIAGE/Insignia de estado")
///
/// Genérica: recibe etiqueta y colores, así sirve para estados del paciente,
/// del incidente o derivados. Atajos:
/// - [TriageStatusBadge.patient] para [PatientLifecycleStatus].
/// - [TriageStatusBadge.rejected] para un traslado rechazado por el hospital.
///
/// La etiqueta se muestra en mayúsculas; si no cabe, se corta con "…".
class TriageStatusBadge extends StatelessWidget {
  const TriageStatusBadge({
    super.key,
    required this.label,
    required this.dotColor,
    required this.textColor,
    required this.background,
  });

  TriageStatusBadge.patient(PatientLifecycleStatus status, {Key? key})
    : this(
        key: key,
        label: status.label,
        dotColor: status.dotColor,
        textColor: status.textColor,
        background: status.background,
      );

  const TriageStatusBadge.rejected({Key? key})
    : this(
        key: key,
        label: 'Rechazado',
        dotColor: TriageColors.danger,
        textColor: TriageColors.danger,
        background: TriageColors.dangerBackground,
      );

  final String label;
  final Color dotColor;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TriageTextStyles.labelSmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
