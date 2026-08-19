import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';

// Muestra un carrusel donde puedes tomar o elegir fotos del lugar
class PhotoUploadSection extends StatefulWidget {
  final List<String>? photos;
  final VoidCallback? onAddPhotoTap;
  final ValueChanged<int>? onRemovePhotoTap;
  final bool isReadOnly;
  final String title;
  final Widget? titleTrailing;

  const PhotoUploadSection({
    super.key,
    this.photos,
    this.onAddPhotoTap,
    this.onRemovePhotoTap,
    this.isReadOnly = false,
    this.title = 'Fotos generales (opcional):',
    this.titleTrailing,
  });

  @override
  State<PhotoUploadSection> createState() => _PhotoUploadSectionState();
}

class _PhotoUploadSectionState extends State<PhotoUploadSection> {
  // Rutas locales de los archivos de imagen capturados o seleccionados
  final List<String> _localPhotos = [];
  final ImagePicker _picker = ImagePicker();

  List<String> get _photos => widget.photos ?? _localPhotos;
  bool get _isControlled => widget.photos != null;

  // Abre la cámara o la galería para elegir una foto
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        if (_isControlled) return;
        setState(() => _localPhotos.add(image.path));
      }
    } catch (e) {
      // Ocurrió un problema al abrir la cámara o galería
    }
  }

  // Muestra la foto en pantalla completa para que puedas hacer zoom
  void _viewFullScreen(String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: InteractiveViewer(
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  // Muestra el menú para elegir entre cámara o galería
  void _showImageSourceDialog() {
    final externalHandler = widget.onAddPhotoTap;
    if (widget.isReadOnly) return;
    if (externalHandler != null) {
      externalHandler();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFCE1125)),
                title: Text(
                  'Tomar foto con la cámara',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFCE1125),
                ),
                title: Text(
                  'Elegir de la galería',
                  style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: 1),
          _photos.isEmpty && widget.isReadOnly
              ? _buildEmptyState()
              : _buildPhotoCarousel(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ),
        if (widget.titleTrailing != null) widget.titleTrailing!,
      ],
    );
  }

  // Lista horizontal de fotos que permite añadir o quitar imágenes
  Widget _buildPhotoCarousel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 109,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _photos.length + (widget.isReadOnly ? 0 : 1),
          separatorBuilder: (context, index) {
            return const SizedBox(width: 15);
          },
          itemBuilder: (context, index) {
            if (!widget.isReadOnly && index == 0) {
              return _buildAddPhotoButton();
            } else {
              final photoIndex = widget.isReadOnly ? index : index - 1;
              return _buildPhotoItem(_photos[photoIndex], photoIndex);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        width: 161,
        height: 109,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Text(
          'Sin fotos',
          style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
            fontSize: 14,
            color: const Color(0xFF999A9D),
          ),
        ),
      ),
    );
  }

  // Botón para abrir el menú y elegir de dónde sacar la foto
  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 161,
        height: 109,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Color(0xFFCE1125), size: 40),
            const SizedBox(height: 4),
            Text(
              'Añadir imagen',
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 14,
                color: const Color(0xFFCE1125),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Muestra una foto específica en la lista y añade la opción de borrarla
  Widget _buildPhotoItem(String imagePath, int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _viewFullScreen(imagePath),
          child: Container(
            width: 161,
            height: 109,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.file(File(imagePath), fit: BoxFit.cover),
            ),
          ),
        ),
        if (!widget.isReadOnly)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () {
                final externalRemove = widget.onRemovePhotoTap;
                if (externalRemove != null) {
                  externalRemove(index);
                } else {
                  setState(() => _localPhotos.removeAt(index));
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFFCE1125),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
