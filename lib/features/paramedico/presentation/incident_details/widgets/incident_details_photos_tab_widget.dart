import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Pestaña Detalles del incidente (B9): fotografías y descripción
class IncidentDetailsPhotosTab extends StatefulWidget {
  final String? description;
  final List<ImageProvider> photos;
  final bool isEditable;
  final bool isUploading;
  final Future<void> Function(String description)? onSaveDescription;
  final VoidCallback? onAddPhotoTap;

  /// Confirma y elimina; devuelve si la foto se eliminó
  final Future<bool> Function(int index)? onRemovePhoto;

  const IncidentDetailsPhotosTab({
    super.key,
    required this.description,
    required this.photos,
    required this.isEditable,
    this.isUploading = false,
    this.onSaveDescription,
    this.onAddPhotoTap,
    this.onRemovePhoto,
  });

  @override
  State<IncidentDetailsPhotosTab> createState() =>
      _IncidentDetailsPhotosTabState();
}

class _IncidentDetailsPhotosTabState extends State<IncidentDetailsPhotosTab> {
  static const double _maxPhotoSize = 140;
  static const double _removeButtonSize = 30;

  bool _editingPhotos = false;

  void _openViewer(int index) {
    showTriagePhotoViewer(
      context,
      photos: widget.photos,
      initialIndex: index,
      onDelete: widget.isEditable ? widget.onRemovePhoto : null,
    );
  }

  Future<void> _editDescription() async {
    var text = widget.description ?? '';
    final result = await showTriageSheet<String>(
      context,
      title: 'Editar descripción',
      dismissible: false,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(TriageSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: TriageSpacing.lg,
          children: [
            TriageField.area(
              label: 'Descripción del incidente',
              initialValue: text,
              onChanged: (value) => text = value,
            ),
            TriageButton(
              label: 'Guardar',
              onPressed: () => Navigator.pop(sheetContext, text),
            ),
          ],
        ),
      ),
    );
    if (result != null) await widget.onSaveDescription?.call(result);
  }

  Widget _photoTile(int index) {
    final remove = widget.onRemovePhoto;
    return Stack(
      fit: StackFit.expand,
      children: [
        TriagePhoto(
          image: widget.photos[index],
          semanticLabel: 'Fotografía ${index + 1}',
          onTap: () => _openViewer(index),
        ),
        if (_editingPhotos && remove != null)
          Align(
            alignment: Alignment.topRight,
            child: TriageIconButton(
              icon: TriageIcons.trash,
              tooltip: 'Eliminar fotografía ${index + 1}',
              variant: TriageIconButtonVariant.surface,
              size: TriageIconButtonSize.small,
              diameter: _removeButtonSize,
              color: TriageColors.danger,
              onPressed: () => remove(index),
            ),
          ),
      ],
    );
  }

  Widget _addTile() {
    if (!widget.isUploading) return TriagePhoto(onTap: widget.onAddPhotoTap);
    return Semantics(
      label: 'Subiendo fotografía',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TriageColors.sunken,
          borderRadius: BorderRadius.circular(TriageRadii.lg),
        ),
        child: Center(
          child: CircularProgressIndicator(color: context.triageRole.accent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final hasPhotos = widget.photos.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: TriageSpacing.lg,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Fotografías del evento',
                  style: TriageTextStyles.titleSmall.copyWith(
                    color: TriageColors.textPrimary,
                  ),
                ),
              ),
            ),
            if (widget.isEditable && hasPhotos)
              TriageSectionAction(
                label: _editingPhotos ? 'Listo' : 'Editar',
                onTap: () => setState(() => _editingPhotos = !_editingPhotos),
              ),
          ],
        ),
        const SizedBox(height: TriageSpacing.md),
        if (!hasPhotos && !widget.isEditable)
          Text(
            'Sin fotografías registradas.',
            style: TriageTextStyles.bodyMedium.copyWith(
              color: TriageColors.textSecondary,
            ),
          )
        else
          GridView.extent(
            maxCrossAxisExtent: _maxPhotoSize,
            mainAxisSpacing: TriageSpacing.sm,
            crossAxisSpacing: TriageSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < widget.photos.length; i++) _photoTile(i),
              if (widget.isEditable) _addTile(),
            ],
          ),
        const SizedBox(height: TriageSpacing.lg),
        TriageSectionCard(
          title: 'Descripción',
          trailing: widget.isEditable
              ? TriageSectionAction(
                  label: 'Editar',
                  icon: TriageIcons.pencil,
                  onTap: _editDescription,
                )
              : null,
          child: Text(
            hasDescription ? description : 'Sin descripción registrada.',
            style: TriageTextStyles.bodyMedium.copyWith(
              color: TriageColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
