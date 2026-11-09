import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Barra de acciones inferior del rediseño (B05, B07 a B16 y C02 a C11)
///
/// [primary] ocupa el ancho disponible; con [secondary] se reparten 2:3, y
/// [leading] (normalmente un `TriageIconButton` grande) va a la izquierda. Crece
/// con el texto y respeta la zona segura. En pantallas con campos conviene
/// colocarla al final del cuerpo, no en `Scaffold.bottomNavigationBar`, para
/// que suba con el teclado.
class TriageActionBar extends StatelessWidget {
  const TriageActionBar({
    super.key,
    required this.primary,
    this.secondary,
    this.leading,
  });

  final Widget primary;
  final Widget? secondary;
  final Widget? leading;

  static const _secondaryFlex = 2;
  static const _primaryFlex = 3;

  @override
  Widget build(BuildContext context) {
    final secondary = this.secondary;
    final gutter = context.horizontalPadding;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TriageColors.surface,
        boxShadow: TriageShadows.bar,
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(
          gutter,
          TriageSpacing.md,
          gutter,
          TriageSpacing.md,
        ),
        // Mismo alto en todos los botones si uno pasa a dos líneas
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TriageSpacing.sm,
            children: [
              ?leading,
              if (secondary != null)
                Expanded(flex: _secondaryFlex, child: secondary),
              Expanded(flex: _primaryFlex, child: primary),
            ],
          ),
        ),
      ),
    );
  }
}
