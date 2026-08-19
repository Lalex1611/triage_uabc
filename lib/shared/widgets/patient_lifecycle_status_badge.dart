import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/patient_status.dart';

class PatientLifecycleStatusBadge extends StatelessWidget {
  const PatientLifecycleStatusBadge({
    super.key,
    required this.status,
    this.isRejected = false,
  });

  final PatientStatus status;
  final bool isRejected;

  static const _rejectedBackground = Color(0xFFFFE4E6);
  static const _rejectedText = Color(0xFFB42318);

  @override
  Widget build(BuildContext context) {
    final background = isRejected ? _rejectedBackground : status.color;
    final foreground = isRejected
        ? _rejectedText
        : status == PatientStatus.trasladando
        ? Colors.white
        : Colors.black;
    final border = status == PatientStatus.alta || isRejected
        ? Border.all(color: Colors.black, width: 0.3)
        : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 86, minHeight: 14),
      child: Container(
        height: 14,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(5),
          border: border,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isRejected ? 'RECHAZADO' : status.label,
            maxLines: 1,
            style: AppTextStyles.ESC_SemiBold_bodyMedium.copyWith(
              fontSize: 9,
              color: foreground,
              letterSpacing: 0,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
