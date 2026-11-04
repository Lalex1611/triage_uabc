import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_steps_widget.dart';

/// Muestra una hoja inferior modal del rediseño con [TriageSheet]
///
/// Se cierra con la X, tocando fuera o arrastrándola hacia abajo, y sube con el
/// teclado. El contenido de [builder] se desplaza si no cabe, así que debe ser
/// de alto ajustado (una `Column`, no un `ListView`). Con `Navigator.pop(context, valor)`
/// devuelve un resultado.
Future<T?> showTriageSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  String? subtitle,
  TriageSteps? steps,
  bool showClose = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: TriageSheet(
        title: title,
        subtitle: subtitle,
        steps: steps,
        onClose: showClose ? () => Navigator.pop(sheetContext) : null,
        child: SingleChildScrollView(child: builder(sheetContext)),
      ),
    ),
  );
}

/// Hoja inferior del rediseño (Figma "Panel" y "Hoja", con "TRIAGE/Agarre")
///
/// Fondo con esquinas superiores redondeadas, agarre y cabecera opcional: [title],
/// [subtitle], [steps] y una X con [onClose], que añade una línea bajo la cabecera.
/// [child] pone sus propios márgenes y puede ser una lista: recibe el alto restante.
///
/// Para una hoja modal usar [showTriageSheet]. Directamente solo en hojas fijas
/// sobre la pantalla (p. ej. la del mapa en B02), que controlan su propio arrastre.
class TriageSheet extends StatelessWidget {
  const TriageSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.steps,
    this.onClose,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final TriageSteps? steps;
  final VoidCallback? onClose;

  static const _radius = BorderRadius.vertical(
    top: Radius.circular(TriageRadii.xxl),
  );

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final subtitle = this.subtitle;
    final steps = this.steps;
    final onClose = this.onClose;

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: _radius,
        boxShadow: TriageShadows.sheet,
      ),
      child: Material(
        color: TriageColors.surface,
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetGrip(),
              if (title != null || subtitle != null || onClose != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: TriageSpacing.xl,
                    end: onClose == null ? TriageSpacing.xl : TriageSpacing.sm,
                    bottom: TriageSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  style: TriageTextStyles.titleMedium.copyWith(
                                    color: TriageColors.textPrimary,
                                  ),
                                ),
                              ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: TriageTextStyles.bodySmall.copyWith(
                                  color: TriageColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onClose != null)
                        IconButton(
                          onPressed: onClose,
                          tooltip: 'Cerrar',
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(
                              TriageSizes.touchTarget,
                            ),
                          ),
                          icon: const TriageIcon(
                            TriageIcons.close,
                            size: TriageSizes.iconLarge,
                            color: TriageColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              if (steps != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: TriageSpacing.xl,
                    right: TriageSpacing.xl,
                    bottom: TriageSpacing.md,
                  ),
                  child: steps,
                ),
              if (onClose != null)
                const Divider(
                  height: TriageSizes.hairline,
                  thickness: TriageSizes.hairline,
                  color: TriageColors.borderSubtle,
                ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de "TRIAGE/Agarre": solo visual, el arrastre lo da la hoja
class _SheetGrip extends StatelessWidget {
  const _SheetGrip();

  static const _width = 44.0;
  static const _height = 5.0;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: TriageSpacing.sm, bottom: TriageSpacing.xs),
      child: Center(
        child: SizedBox(
          width: _width,
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TriageColors.borderStrong,
              borderRadius: BorderRadius.all(Radius.circular(TriageRadii.full)),
            ),
          ),
        ),
      ),
    );
  }
}
