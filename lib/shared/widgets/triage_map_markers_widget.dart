import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Marcadores de mapa del rediseño (Figma "TRIAGE/Marcador de ...")
///
/// Van dentro de un `Marker` de flutter_map. Con `onTap`, conviene darle al
/// `Marker` [TriageSizes.touchTarget] de lado: toda esa zona responde al toque.

const double _whiteRing = 3;
const double _placeMarkerSize = 38;

/// Marcador de paciente: punto del color de [level]
///
/// [highlighted] añade un aro del color del rol; Figma no define este estado,
/// pero el mapa actual marca así al paciente seleccionado.
class TriagePatientMarker extends StatelessWidget {
  const TriagePatientMarker(
    this.level, {
    super.key,
    this.highlighted = false,
    this.onTap,
    this.semanticLabel,
  });

  final TriageLevel level;
  final bool highlighted;
  final VoidCallback? onTap;
  final String? semanticLabel;

  static const _size = 26.0;

  @override
  Widget build(BuildContext context) {
    final dot = SizedBox.square(
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: level.color,
          shape: BoxShape.circle,
          border: Border.all(color: TriageColors.surface, width: _whiteRing),
          boxShadow: TriageShadows.marker,
        ),
      ),
    );

    return _MarkerTarget(
      label: semanticLabel ?? 'Paciente en ${level.label.toLowerCase()}',
      selected: highlighted,
      onTap: onTap,
      child: highlighted
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.triageRole.accent,
                  width: TriageSizes.strokeStrong,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(TriageSpacing.xxs),
                child: dot,
              ),
            )
          : dot,
    );
  }
}

/// Marcador de hospital. [semanticLabel] puede dar su nombre al lector de pantalla
class TriageHospitalMarker extends StatelessWidget {
  const TriageHospitalMarker({
    super.key,
    this.onTap,
    this.semanticLabel = 'Hospital',
  });

  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => _PlaceMarker(
    icon: TriageIcons.hospital,
    iconColor: TriageColors.hospitalAccent,
    label: semanticLabel,
    onTap: onTap,
  );
}

/// Marcador de unidad de ambulancia
class TriageUnitMarker extends StatelessWidget {
  const TriageUnitMarker({
    super.key,
    this.onTap,
    this.semanticLabel = 'Unidad de ambulancia',
  });

  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => _PlaceMarker(
    icon: TriageIcons.ambulance,
    iconColor: TriageColors.textPrimary,
    label: semanticLabel,
    onTap: onTap,
  );
}

/// Marcador de la posición del usuario. Azul en los dos roles, como en Figma
class TriageUserMarker extends StatelessWidget {
  const TriageUserMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return _MarkerTarget(
      label: 'Tu ubicación',
      onTap: null,
      child: SizedBox.square(
        dimension: _placeMarkerSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TriageColors.hospitalAccent,
            shape: BoxShape.circle,
            border: Border.all(color: TriageColors.surface, width: _whiteRing),
            boxShadow: TriageShadows.marker,
          ),
          child: const Center(
            child: TriageIcon(
              TriageIcons.navigation,
              size: TriageSizes.icon,
              color: TriageColors.textInverse,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _MarkerTarget(
      label: label,
      onTap: onTap,
      child: SizedBox.square(
        dimension: _placeMarkerSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TriageColors.surface,
            borderRadius: BorderRadius.circular(TriageRadii.md),
            border: Border.all(
              color: TriageColors.borderMedium,
              width: TriageSizes.stroke,
            ),
            boxShadow: TriageShadows.marker,
          ),
          child: Center(
            child: TriageIcon(icon, size: TriageSizes.icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/// Zona táctil y lectura en pantalla comunes a los marcadores
class _MarkerTarget extends StatelessWidget {
  const _MarkerTarget({
    required this.label,
    required this.onTap,
    required this.child,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: onTap == null ? 0 : TriageSizes.touchTarget,
            minHeight: onTap == null ? 0 : TriageSizes.touchTarget,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
