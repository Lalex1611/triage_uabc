import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Foto del rediseño (Figma "TRIAGE/Foto", B05, B12 y C06)
///
/// Cuadrada, ocupa el ancho que le da su contenedor: en una fila va dentro de
/// `Expanded` o en un `GridView`. Sin [image] es el recuadro punteado "Añadir";
/// con [image] muestra la foto y, mientras carga o si falla, un ícono. Figma usa
/// texto terciario y un ícono blanco (menos de 3:1); aquí van en texto secundario.
class TriagePhoto extends StatelessWidget {
  const TriagePhoto({super.key, this.image, this.onTap, this.semanticLabel});

  final ImageProvider? image;
  final VoidCallback? onTap;

  /// Texto para el lector de pantalla; por defecto, según haya foto o no
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = this.image;

    return Semantics(
      container: true,
      button: onTap != null,
      image: image != null,
      label:
          semanticLabel ?? (image == null ? 'Añadir fotografía' : 'Fotografía'),
      onTap: onTap,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TriageRadii.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image == null)
                const _EmptyPhoto()
              else ...[
                const ColoredBox(
                  color: TriageColors.borderStrong,
                  child: Center(
                    child: TriageIcon(
                      TriageIcons.image,
                      size: TriageSizes.iconLarge,
                      color: TriageColors.textSecondary,
                    ),
                  ),
                ),
                Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ],
              Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(),
      child: ColoredBox(
        color: TriageColors.sunken,
        child: Padding(
          padding: const EdgeInsets.all(TriageSpacing.xs),
          child: Center(
            // El recuadro puede ser estrecho: con texto grande se reduce sin desbordarse
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TriageIcon(
                    TriageIcons.camera,
                    size: TriageSizes.iconLarge,
                    color: TriageColors.textSecondary,
                  ),
                  const SizedBox(height: TriageSpacing.xs),
                  Text(
                    'Añadir',
                    style: TriageTextStyles.labelSmall.copyWith(
                      color: TriageColors.textSecondary,
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

/// Flutter no trae borde punteado: recorre el contorno y pinta tramos
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = TriageSizes.stroke / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = TriageSizes.stroke
      ..color = TriageColors.borderMedium;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(inset),
          const Radius.circular(TriageRadii.lg - inset),
        ),
      );

    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
