import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Hoja de consulta rápida del protocolo de triage START (B19).
class ParamedicoStartGuide extends StatelessWidget {
  const ParamedicoStartGuide({super.key, this.onBack});

  /// Acción al pulsar la flecha de regreso. Si es null, ejecuta [Navigator.maybePop].
  final VoidCallback? onBack;

  /// Despliega la guía dentro del navegador de la rama activa ([host]) para que
  /// quede debajo de la barra de búsqueda y por detrás de [ParamedicoNavbar].
  static Future<void> show(BuildContext context, {BuildContext? host}) {
    final targetContext = host ?? context;
    return showModalBottomSheet<void>(
      context: targetContext,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: TriageColors.surface.withValues(alpha: 0),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return SizedBox(
          height: media.size.height * 0.92,
          child: ParamedicoStartGuide(
            onBack: () => Navigator.of(sheetContext).pop(),
          ),
        );
      },
    );
  }

  static ({Color background, Color foreground}) _colorsForLevel(
    TriageLevel level,
  ) {
    switch (level) {
      case TriageLevel.red:
        return (
          background: TriageColors.triageRed,
          foreground: TriageColors.textInverse,
        );
      case TriageLevel.orange:
        return (
          background: TriageColors.triageOrange,
          foreground: TriageColors.textInverse,
        );
      case TriageLevel.yellow:
        return (
          background: TriageColors.triageYellow,
          foreground: TriageColors.textPrimary,
        );
      case TriageLevel.green:
        return (
          background: TriageColors.triageGreen,
          foreground: TriageColors.textPrimary,
        );
      case TriageLevel.black:
        return (
          background: TriageColors.triageBlack,
          foreground: TriageColors.textInverse,
        );
      case TriageLevel.blue:
        return (
          background: TriageColors.triageBlue,
          foreground: TriageColors.textInverse,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TriageRadii.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: TriageColors.textPrimary.withValues(alpha: 0.12),
            blurRadius: TriageSpacing.lg,
            offset: const Offset(0, -TriageSpacing.xs),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado fijo con manija superior, flecha atrás y título
          Container(
            padding: const EdgeInsets.fromLTRB(
              TriageSpacing.lg,
              TriageSpacing.sm,
              TriageSpacing.lg,
              TriageSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: TriageColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(TriageRadii.xl),
              ),
              border: Border(
                bottom: BorderSide(color: TriageColors.borderSubtle),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: TriageSpacing.xl + TriageSpacing.md,
                  height: TriageSpacing.xs,
                  decoration: const ShapeDecoration(
                    color: TriageColors.borderMedium,
                    shape: StadiumBorder(),
                  ),
                ),
                const SizedBox(height: TriageSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 36,
                      child: IconButton(
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: TriageColors.textPrimary,
                          size: TriageSizes.icon,
                        ),
                      ),
                    ),
                    const SizedBox(width: TriageSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guía rápida START',
                            style: TriageTextStyles.titleMedium.copyWith(
                              color: TriageColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consulta de referencia',
                            style: TriageTextStyles.bodySmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista desplazable con los 5 pasos del protocolo y leyenda de colores
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                TriageSpacing.lg,
                TriageSpacing.md,
                TriageSpacing.lg,
                bottomInset + (TriageSpacing.xl * 3),
              ),
              children: const [
                _StartStepCard(
                  icon: Icons.directions_walk_rounded,
                  stepLabel: 'PASO 1 · CAMINAR',
                  question: '¿Camina por sí mismo?',
                  outcomeLabel: 'Sí → Verde',
                  level: TriageLevel.green,
                ),
                SizedBox(height: TriageSpacing.md),
                _StartStepCard(
                  icon: Icons.air_rounded,
                  stepLabel: 'PASO 2 · RESPIRACIÓN',
                  question: '¿Respira al abrir la vía aérea?',
                  outcomeLabel: 'No → Negro',
                  level: TriageLevel.black,
                ),
                SizedBox(height: TriageSpacing.md),
                _StartStepCard(
                  customIcon: _PulseWaveIcon(
                    color: TriageColors.paramedicAccent,
                    size: _StartStepCard.iconSize,
                  ),
                  stepLabel: 'PASO 3 · FRECUENCIA',
                  question: '¿Más de 30 respiraciones por minuto?',
                  outcomeLabel: 'Sí → Rojo',
                  level: TriageLevel.red,
                ),
                SizedBox(height: TriageSpacing.md),
                _StartStepCard(
                  icon: Icons.water_drop_outlined,
                  stepLabel: 'PASO 4 · CIRCULACIÓN',
                  question: '¿Llenado capilar mayor a 2 s o sin pulso radial?',
                  outcomeLabel: 'Sí → Rojo',
                  level: TriageLevel.red,
                ),
                SizedBox(height: TriageSpacing.md),
                _StartStepCard(
                  customIcon: _BrainOutlineIcon(
                    color: TriageColors.paramedicAccent,
                    size: _StartStepCard.iconSize,
                  ),
                  stepLabel: 'PASO 5 · NEUROLÓGICO',
                  question: '¿Obedece órdenes simples?',
                  outcomeLabel: 'No → Rojo · Sí → Amarillo',
                  level: TriageLevel.yellow,
                ),
                SizedBox(height: TriageSpacing.md),
                _StartColorLegendCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartStepCard extends StatelessWidget {
  const _StartStepCard({
    this.icon,
    this.customIcon,
    required this.stepLabel,
    required this.question,
    required this.outcomeLabel,
    required this.level,
  }) : assert(icon != null || customIcon != null);

  static const double iconSize = TriageSizes.icon + 6;
  static const double _iconBoxSize = 48;

  final IconData? icon;
  final Widget? customIcon;
  final String stepLabel;
  final String question;
  final String outcomeLabel;
  final TriageLevel level;

  @override
  Widget build(BuildContext context) {
    final badgeColors = ParamedicoStartGuide._colorsForLevel(level);

    return Container(
      padding: const EdgeInsets.all(TriageSpacing.lg),
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(TriageRadii.lg),
        border: Border.all(color: TriageColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _iconBoxSize,
                height: _iconBoxSize,
                decoration: BoxDecoration(
                  color: TriageColors.paramedicSoft,
                  borderRadius: BorderRadius.circular(TriageRadii.md),
                ),
                child: Center(
                  child:
                      customIcon ??
                      Icon(
                        icon,
                        color: TriageColors.paramedicAccent,
                        size: iconSize,
                      ),
                ),
              ),
              const SizedBox(width: TriageSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepLabel,
                      style: TriageTextStyles.labelSmall.copyWith(
                        color: TriageColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: TriageSpacing.xs),
                    Text(
                      question,
                      style: TriageTextStyles.titleMedium.copyWith(
                        color: TriageColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TriageSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TriageSpacing.md,
              vertical: 6,
            ),
            decoration: ShapeDecoration(
              color: badgeColors.background,
              shape: const StadiumBorder(),
            ),
            child: Text(
              outcomeLabel,
              style: TriageTextStyles.labelSmall.copyWith(
                color: badgeColors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartColorLegendCard extends StatelessWidget {
  const _StartColorLegendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TriageSpacing.lg),
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(TriageRadii.lg),
        border: Border.all(color: TriageColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qué significa cada color',
            style: TriageTextStyles.titleMedium.copyWith(
              color: TriageColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TriageSpacing.md),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ColorMeaningTile(
                    code: 'ROJO',
                    title: 'Inmediato',
                    description: 'No camina · no responde',
                    level: TriageLevel.red,
                  ),
                ),
                SizedBox(width: TriageSpacing.sm + 2),
                Expanded(
                  child: _ColorMeaningTile(
                    code: 'AMARILLO',
                    title: 'Urgente',
                    description: 'Puede esperar atención',
                    level: TriageLevel.yellow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TriageSpacing.sm + 2),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ColorMeaningTile(
                    code: 'VERDE',
                    title: 'Leve',
                    description: 'Camina por sí mismo',
                    level: TriageLevel.green,
                  ),
                ),
                SizedBox(width: TriageSpacing.sm + 2),
                Expanded(
                  child: _ColorMeaningTile(
                    code: 'NEGRO',
                    title: 'Fallecido',
                    description: 'Sin signos vitales',
                    level: TriageLevel.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorMeaningTile extends StatelessWidget {
  const _ColorMeaningTile({
    required this.code,
    required this.title,
    required this.description,
    required this.level,
  });

  final String code;
  final String title;
  final String description;
  final TriageLevel level;

  @override
  Widget build(BuildContext context) {
    final tileColors = ParamedicoStartGuide._colorsForLevel(level);

    return Container(
      padding: const EdgeInsets.all(TriageSpacing.md),
      decoration: BoxDecoration(
        color: tileColors.background,
        borderRadius: BorderRadius.circular(TriageRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            code,
            style: TriageTextStyles.labelSmall.copyWith(
              color: tileColors.foreground.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TriageTextStyles.titleMedium.copyWith(
              color: tileColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TriageSpacing.xs),
          Text(
            description,
            style: TriageTextStyles.bodySmall.copyWith(
              color: tileColors.foreground.withValues(alpha: 0.92),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseWaveIcon extends StatelessWidget {
  const _PulseWaveIcon({
    required this.color,
    this.size = _StartStepCard.iconSize,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PulseWavePainter(color: color)),
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  const _PulseWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final midY = h * 0.52;

    final path = Path()
      ..moveTo(w * 0.12, midY)
      ..lineTo(w * 0.34, midY)
      ..lineTo(w * 0.44, h * 0.24)
      ..lineTo(w * 0.56, h * 0.80)
      ..lineTo(w * 0.66, midY)
      ..lineTo(w * 0.88, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BrainOutlineIcon extends StatelessWidget {
  const _BrainOutlineIcon({
    required this.color,
    this.size = _StartStepCard.iconSize,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BrainOutlinePainter(color: color)),
    );
  }
}

class _BrainOutlinePainter extends CustomPainter {
  const _BrainOutlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Línea divisoria central entre hemisferios
    canvas.drawLine(Offset(cx, h * 0.16), Offset(cx, h * 0.84), paint);

    // Hemisferio izquierdo
    final left = Path()
      ..moveTo(cx, h * 0.18)
      ..cubicTo(w * 0.24, h * 0.14, w * 0.14, h * 0.30, w * 0.20, h * 0.44)
      ..cubicTo(w * 0.12, h * 0.54, w * 0.16, h * 0.72, w * 0.28, h * 0.78)
      ..cubicTo(w * 0.34, h * 0.86, cx, h * 0.86, cx, h * 0.80);

    // Hemisferio derecho
    final right = Path()
      ..moveTo(cx, h * 0.18)
      ..cubicTo(w * 0.76, h * 0.14, w * 0.86, h * 0.30, w * 0.80, h * 0.44)
      ..cubicTo(w * 0.88, h * 0.54, w * 0.84, h * 0.72, w * 0.72, h * 0.78)
      ..cubicTo(w * 0.66, h * 0.86, cx, h * 0.86, cx, h * 0.80);

    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(covariant _BrainOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
