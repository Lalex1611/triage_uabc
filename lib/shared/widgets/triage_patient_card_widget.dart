import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_level_style.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_status_badge_widget.dart';

/// Tarjeta de paciente del rediseño (Figma "TRIAGE/Tarjeta de paciente")
///
/// - Por defecto (B07, lista del incidente): barra con el color de [level] e
///   insignia debajo del detalle.
/// - [TriagePatientCard.room] (C05, sala hospitalaria): cuadro "NIVEL n" del
///   triage hospitalario e insignia junto al nombre.
///
/// [badge] es la insignia del estado (`TriageStatusBadge.patient(...)`,
/// `.rejected()`…). Toda la tarjeta responde a [onTap]; el lector de pantalla
/// la anuncia como un solo botón con nombre, nivel, detalle y estado.
class TriagePatientCard extends StatelessWidget {
  const TriagePatientCard({
    super.key,
    required this.name,
    required this.detail,
    required this.level,
    this.badge,
    this.onTap,
  }) : _room = false;

  /// [level] debe ser uno de [TriageLevel.hospitalLevels] (nivel 1 a 5)
  const TriagePatientCard.room({
    super.key,
    required this.name,
    required this.detail,
    required this.level,
    this.badge,
    this.onTap,
  }) : assert(level != TriageLevel.black),
       _room = true;

  final String name;
  final String detail;
  final TriageLevel level;
  final TriageStatusBadge? badge;
  final VoidCallback? onTap;
  final bool _room;

  static const _radius = BorderRadius.all(Radius.circular(TriageRadii.xl));
  static const _chevron = TriageIcon(
    TriageIcons.chevronRight,
    size: TriageSizes.icon,
    color: TriageColors.textTertiary,
  );

  /// Ancho de la barra de color (Figma)
  static const double _levelBarWidth = 19;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    final nameText = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TriageTextStyles.labelLarge.copyWith(
        color: TriageColors.textPrimary,
      ),
    );
    final detailText = Text(
      detail,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TriageTextStyles.bodySmall.copyWith(
        color: TriageColors.textSecondary,
      ),
    );

    final content = _room
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // La insignia toma su ancho hasta un 60 % de la fila; con texto
              // grande se parte en líneas en vez de empujar el nombre fuera
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(child: nameText),
                    if (badge != null) ...[
                      const SizedBox(width: TriageSpacing.sm),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.6,
                        ),
                        child: badge,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: TriageSpacing.xs),
              detailText,
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameText,
              const SizedBox(height: TriageSpacing.xs),
              detailText,
              if (badge != null) ...[
                const SizedBox(height: TriageSpacing.sm),
                badge,
              ],
            ],
          );

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TriageColors.surface,
            borderRadius: _radius,
            border: Border.all(
              color: TriageColors.borderSubtle,
              width: TriageSizes.stroke,
            ),
            boxShadow: TriageShadows.card,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: _radius,
              child: Padding(
                // Mismo relleno que la tarjeta de incidente
                padding: const EdgeInsets.all(TriageSpacing.lg),
                child: _room
                    ? Row(
                        children: [
                          _LevelTile(level),
                          const SizedBox(width: TriageSpacing.md),
                          Expanded(child: content),
                          const SizedBox(width: TriageSpacing.md),
                          _chevron,
                        ],
                      )
                    // IntrinsicHeight: la barra de color mide lo mismo que el contenido
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              label: 'Triage ${level.label}',
                              child: Container(
                                width: _levelBarWidth,
                                constraints: const BoxConstraints(
                                  minHeight: TriageSizes.touchTarget,
                                ),
                                decoration: BoxDecoration(
                                  color: level.color,
                                  borderRadius: BorderRadius.circular(
                                    TriageRadii.full,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: TriageSpacing.md),
                            Expanded(child: content),
                            const SizedBox(width: TriageSpacing.md),
                            const Center(child: _chevron),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuadro "NIVEL n" del triage hospitalario (C05)
class _LevelTile extends StatelessWidget {
  const _LevelTile(this.level);

  final TriageLevel level;

  @override
  Widget build(BuildContext context) {
    final number = TriageLevel.hospitalLevels.indexOf(level) + 1;
    return Semantics(
      label: 'Nivel $number, ${level.label}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: TriageSizes.touchTargetCompact,
          minHeight: TriageSizes.touchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: TriageSpacing.xs),
        decoration: BoxDecoration(
          color: level.color,
          borderRadius: BorderRadius.circular(TriageRadii.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Etiqueta/Chica sin reducir: los 8 px de Figma no son legibles
            Text(
              'NIVEL',
              style: TriageTextStyles.labelSmall.copyWith(color: level.onColor),
            ),
            Text(
              '$number',
              style: TriageTextStyles.dataLarge.copyWith(color: level.onColor),
            ),
          ],
        ),
      ),
    );
  }
}
