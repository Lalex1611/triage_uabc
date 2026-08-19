import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/widgets/photo_upload_section_widget.dart';

class IncidentDetailsPhotosTab extends StatefulWidget {
  final String? description;
  final List<String> photos;
  final bool isEditable;
  final Future<void> Function(String description)? onSaveDescription;
  final VoidCallback? onAddPhotoTap;
  final ValueChanged<int>? onRemovePhotoTap;

  const IncidentDetailsPhotosTab({
    super.key,
    required this.description,
    required this.photos,
    required this.isEditable,
    this.onSaveDescription,
    this.onAddPhotoTap,
    this.onRemovePhotoTap,
  });

  @override
  State<IncidentDetailsPhotosTab> createState() =>
      _IncidentDetailsPhotosTabState();
}

class _IncidentDetailsPhotosTabState extends State<IncidentDetailsPhotosTab> {
  late final TextEditingController _descriptionController;
  bool _editingPhotos = false;
  bool _editingDescription = false;
  bool _savingDescription = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.description ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant IncidentDetailsPhotosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingDescription && widget.description != oldWidget.description) {
      _descriptionController.text = widget.description ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _startDescriptionEdit() {
    _descriptionController.text = widget.description ?? '';
    setState(() => _editingDescription = true);
  }

  void _cancelDescriptionEdit() {
    _descriptionController.text = widget.description ?? '';
    setState(() => _editingDescription = false);
  }

  Future<void> _saveDescription() async {
    final save = widget.onSaveDescription;
    if (save == null || _savingDescription) return;
    setState(() => _savingDescription = true);
    try {
      await save(_descriptionController.text);
      if (!mounted) return;
      setState(() => _editingDescription = false);
    } finally {
      if (mounted) setState(() => _savingDescription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEditPhotos = widget.isEditable && _editingPhotos;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 120),
      children: [
        PhotoUploadSection(
          photos: widget.photos,
          isReadOnly: !canEditPhotos,
          onAddPhotoTap: canEditPhotos ? widget.onAddPhotoTap : null,
          onRemovePhotoTap: canEditPhotos ? widget.onRemovePhotoTap : null,
          title: 'Fotos generales:',
          titleTrailing: widget.isEditable
              ? _EditToggleButton(
                  isEditing: _editingPhotos,
                  onTap: () => setState(() => _editingPhotos = !_editingPhotos),
                )
              : null,
        ),
        const SizedBox(height: 18),
        _IncidentDescriptionCard(
          description: widget.description,
          controller: _descriptionController,
          isEditable: widget.isEditable,
          isEditing: _editingDescription,
          isSaving: _savingDescription,
          onStartEdit: _startDescriptionEdit,
          onCancel: _cancelDescriptionEdit,
          onSave: _saveDescription,
        ),
      ],
    );
  }
}

class _EditToggleButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onTap;

  const _EditToggleButton({required this.isEditing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        isEditing ? Icons.check_rounded : Icons.edit_rounded,
        size: 16,
      ),
      label: Text(isEditing ? 'Listo' : 'Editar'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryParamedico,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _IncidentDescriptionCard extends StatelessWidget {
  final String? description;
  final TextEditingController controller;
  final bool isEditable;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onStartEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _IncidentDescriptionCard({
    required this.description,
    required this.controller,
    required this.isEditable,
    required this.isEditing,
    required this.isSaving,
    required this.onStartEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final value = description?.trim();
    final hasDescription = value != null && value.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Descripción del incidente:',
                  style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
              if (isEditable && !isEditing)
                _EditToggleButton(isEditing: false, onTap: onStartEdit),
              if (isEditable && isEditing) ...[
                TextButton(
                  onPressed: isSaving ? null : onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: isSaving ? null : onSave,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryParamedico,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(isSaving ? 'Guardando' : 'Guardar'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: isEditing
                ? TextField(
                    controller: controller,
                    minLines: 4,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    hasDescription ? value : 'Sin descripción registrada.',
                    style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                      fontSize: 14,
                      color: hasDescription
                          ? Colors.black
                          : const Color(0xFF999A9D),
                      height: 1.25,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
