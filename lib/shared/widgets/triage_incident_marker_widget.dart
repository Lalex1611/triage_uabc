import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Marcador de incidente en el mapa (Figma: píldora con alerta y conteo)
///
/// Muestra el número de pacientes en rojo del incidente. Siempre es rojo
/// (color de rol paramédico). Seleccionado: relleno rojo y texto blanco.
/// Pensado para ir dentro de un `Marker` de flutter_map, que tiene tamaño fijo,
/// por eso el contenido se reduce (FittedBox) en vez de desbordarse con
/// texto al 200 %.
class TriageIncidentMarker extends StatelessWidget {
  const TriageIncidentMarker({
    super.key,
    required this.redCount,
    required this.onTap,
    this.selected = false,
  });

  final int redCount;
  final bool selected;
  final VoidCallback? onTap;

  // Medidas que solo tiene esta pieza
  static const double _badgeSize = 24;
  static const double _alertIconSize = 14;

  @override
  Widget build(BuildContext context) {
    const accent = TriageColors.paramedicAccent;
    final background = selected ? accent : TriageColors.surface;
    final badgeColor = selected ? TriageColors.surface : accent;
    final badgeIconColor = selected ? accent : TriageColors.textInverse;
    final countColor = selected ? TriageColors.textInverse : accent;

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: redCount == 1
          ? 'Incidente con 1 paciente en rojo'
          : 'Incidente con $redCount pacientes en rojo',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              constraints: const BoxConstraints(minHeight: _badgeSize),
              padding: const EdgeInsets.all(TriageSpacing.xs),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(TriageRadii.full),
                border: Border.all(color: accent, width: TriageSizes.stroke),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: TriageIcon(
                        TriageIcons.alert,
                        size: _alertIconSize,
                        color: badgeIconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: TriageSpacing.sm),
                  Text(
                    '$redCount',
                    style: TriageTextStyles.labelMedium.copyWith(
                      color: countColor,
                    ),
                  ),
                  const SizedBox(width: TriageSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}