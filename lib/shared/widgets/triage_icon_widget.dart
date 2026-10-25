import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Ícono del rediseño: pinta un SVG de [TriageIcons] en un solo color
///
/// Se comporta como `Icon`: sin [size] ni [color] los toma del `IconTheme`
/// más cercano (bajo `MaterialApp` siempre hay uno: el `iconTheme` de la app),
/// así un componente puede teñir todos sus íconos con un solo `IconTheme`.
/// Los componentes del rediseño pasan [color] explícito según Figma.
/// Sin [semanticLabel] se considera decorativo y no se anuncia al lector de pantalla.
class TriageIcon extends StatelessWidget {
  const TriageIcon(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  /// Ruta de [TriageIcons]
  final String asset;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor = color ?? iconTheme.color ?? TriageColors.textPrimary;

    return SvgPicture.asset(
      asset,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
