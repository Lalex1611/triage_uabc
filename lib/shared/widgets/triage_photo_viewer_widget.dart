import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_button_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';

/// Visor de fotografías a pantalla completa (Figma "D18 · Visor de fotografía")
///
/// Se pasa de una foto a otra deslizando y se acerca con pellizco. Con [onDelete]
/// muestra la papelera; debe confirmar y devolver si la foto se eliminó, y en ese
/// caso el visor se cierra.
Future<void> showTriagePhotoViewer(
  BuildContext context, {
  required List<ImageProvider> photos,
  int initialIndex = 0,
  Future<bool> Function(int index)? onDelete,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _PhotoViewer(
      photos: photos,
      initialIndex: initialIndex,
      onDelete: onDelete,
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  final List<ImageProvider> photos;
  final int initialIndex;
  final Future<bool> Function(int index)? onDelete;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  static const double _dotSize = 8;

  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _delete(Future<bool> Function(int index) onDelete) async {
    final deleted = await onDelete(_index);
    if (deleted && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final onDelete = widget.onDelete;
    final total = widget.photos.length;

    return Dialog.fullscreen(
      backgroundColor: TriageColors.inverse,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TriageSpacing.sm,
                vertical: TriageSpacing.xs,
              ),
              child: Row(
                spacing: TriageSpacing.xs,
                children: [
                  TriageIconButton(
                    icon: TriageIcons.close,
                    tooltip: 'Cerrar',
                    variant: TriageIconButtonVariant.onAccent,
                    color: TriageColors.textInverse,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        'Foto ${_index + 1} de $total',
                        style: TriageTextStyles.labelLarge.copyWith(
                          color: TriageColors.textInverse,
                        ),
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    TriageIconButton(
                      icon: TriageIcons.trash,
                      tooltip: 'Eliminar fotografía',
                      variant: TriageIconButtonVariant.onAccent,
                      color: TriageColors.textInverse,
                      onPressed: () => _delete(onDelete),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                // Con la foto acercada, arrastrar debe moverla, no cambiar de página
                physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                itemCount: total,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (_, index) => _ZoomablePhoto(
                  image: widget.photos[index],
                  onZoomChanged: (zoomed) {
                    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                  },
                ),
              ),
            ),
            if (total > 1)
              Padding(
                padding: const EdgeInsets.all(TriageSpacing.lg),
                child: ExcludeSemantics(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: TriageSpacing.sm,
                    runSpacing: TriageSpacing.sm,
                    children: [
                      for (var i = 0; i < total; i++)
                        SizedBox.square(
                          dimension: _dotSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _index
                                  ? TriageColors.textInverse
                                  : TriageColors.textInverse.withValues(
                                      alpha: TriageOpacity.disabled,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.image, required this.onZoomChanged});

  final ImageProvider image;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  static const double _maxScale = 4;

  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      maxScale: _maxScale,
      onInteractionEnd: (_) =>
          widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1),
      child: Center(
        child: Image(
          image: widget.image,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const TriageIcon(
            TriageIcons.image,
            size: TriageSizes.iconLarge,
            color: TriageColors.textInverse,
          ),
        ),
      ),
    );
  }
}
