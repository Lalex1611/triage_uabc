import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Barra inferior del incidente: «Registrar paciente», o «Cerrar incidente» en
/// Resumen para quien puede cerrarlo
class IncidentActionButtons extends StatelessWidget {
  final bool isStatsTab;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onCloseIncidentTap;

  const IncidentActionButtons({
    super.key,
    this.isStatsTab = false,
    this.onRegisterTap,
    this.onCloseIncidentTap,
  });

  @override
  Widget build(BuildContext context) {
    return TriageActionBar(
      // Sin onCloseIncidentTap, quien no puede cerrarlo sigue pudiendo registrar
      primary: isStatsTab && onCloseIncidentTap != null
          ? TriageButton(
              label: 'Cerrar incidente',
              variant: TriageButtonVariant.danger,
              onPressed: onCloseIncidentTap,
            )
          : TriageButton(label: 'Registrar paciente', onPressed: onRegisterTap),
    );
  }
}
