import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/medico/domain/entities/home/medico_patient_card_data.dart';
import 'package:sistema_triage/features/medico/presentation/home/widgets/medico_patient_card_widget.dart';

/// Caja única: tarjeta del incidente arriba y **debajo** (fuera de la tarjeta)
/// los controles de ingreso en traslado (ACEPTAR / RECHAZAR)
class MedicoPatientIncomingTransferShell extends StatelessWidget {
  const MedicoPatientIncomingTransferShell({
    super.key,
    required this.data,
  });

  final MedicoPatientCardData data;

  static const double _radius = 13.2;

  @override
  Widget build(BuildContext context) {
    final accept = data.onIncomingAcceptTap;
    final reject = data.onIncomingRejectTap;
    if (accept == null || reject == null) {
      return MedicoPatientCard(data: data.withoutIncomingCallbacks());
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicoPatientCard(
            data: data.withoutIncomingCallbacks(),
            panelOnly: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryMedico.withValues(alpha: 0.06),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(child: _chip(label: 'RECHAZAR', outlined: true, onTap: reject)),
                  const SizedBox(width: 10),
                  Expanded(child: _chip(label: 'ACEPTAR', outlined: false, onTap: accept)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool outlined,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : AppColors.primaryMedico,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryMedico, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: outlined ? 0.06 : 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
            fontSize: 11,
            letterSpacing: 0.35,
            color: outlined ? AppColors.primaryMedico : Colors.white,
          ),
        ),
      ),
    );
  }
}
