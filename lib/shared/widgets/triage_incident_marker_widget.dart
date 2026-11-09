import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Marcador de incidente en el mapa (Figma "TRIAGE/Marcador de incidente")
///
/// Muestra el total de pacientes del incidente. Siempre es rojo
/// (color de rol paramédico). Seleccionado: relleno rojo y texto blanco.
/// Pensado para ir dentro de un `Marker` de flutter_map, que tiene tamaño fijo,
/// por eso el contenido se reduce (FittedBox) en vez de desbordarse con
/// texto al 200 %.
class TriageIncidentMarker extends StatelessWidget {
  const TriageIncidentMarker({
    super.key,
    required this.patientCount,
    required this.onTap,
    this.selected = false,
  });

  final int patientCount;
  final bool selected;
  final VoidCallback? onTap;

  // Medidas que solo tiene esta pieza
  static const double _height = 42;
  static const double _selectedHeight = 48;
  static const double _badgeSize = 28;
  static const double _selectedBadgeSize = 34;

  @override
  Widget build(BuildContext context) {
    const accent = TriageColors.paramedicAccent;
    final badgeSize = selected ? _selectedBadgeSize : _badgeSize;

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: patientCount == 1
          ? 'Incidente con 1 paciente'
          : 'Incidente con $patientCount pacientes',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              constraints: BoxConstraints(
                minHeight: selected ? _selectedHeight : _height,
              ),
              padding: const EdgeInsets.only(
                left: TriageSpacing.sm,
                right: TriageSpacing.md,
              ),
              decoration: BoxDecoration(
                color: selected ? accent : TriageColors.surface,
                borderRadius: BorderRadius.circular(TriageRadii.full),
                border: selected
                    ? null
                    : Border.all(
                        color: accent,
                        width: TriageSizes.strokeStrong,
                      ),
                boxShadow: TriageShadows.floating,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: selected ? TriageColors.surface : accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: TriageIcon(
                      TriageIcons.alert,
                      size: selected
                          ? TriageSizes.iconSmall
                          : TriageSizes.iconXSmall,
                      color: selected ? accent : TriageColors.textInverse,
                    ),
                  ),
                  const SizedBox(width: TriageSpacing.sm),
                  Text(
                    '$patientCount',
                    style: TriageTextStyles.labelLarge.copyWith(
                      color: selected
                          ? TriageColors.textInverse
                          : TriageColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
