import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/patient_registration/patient_photo_data.dart';

class PatientPhotoWidget extends StatelessWidget {
  final PatientPhotoData data;

  const PatientPhotoWidget({super.key, required this.data});

  bool get _directCapture =>
      !data.isReadOnly && data.onCameraTap != null && data.onGalleryTap != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!data.isReadOnly) ...[
            Center(
              child: Text(
                'Capture la fotografía del paciente',
                style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 23),
          ],
          _buildPhotoRow(context),
        ],
      ),
    );
  }

  Widget _buildPhotoRow(BuildContext context) {
    if (data.showSinFotoGalleryRow) {
      return _buildSinFotoGalleryRow(context);
    }

    if (data.isReadOnly && data.photos.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 140,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: Text(
            'Sin fotos',
            style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
              color: const Color(0xFF999A9D),
            ),
          ),
        ),
      );
    }

    if (_directCapture && data.photos.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: _captureTile(
              icon: Icons.camera_alt_rounded,
              label: 'Cámara',
              onTap: data.onCameraTap!,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _captureTile(
              icon: Icons.photo_library_rounded,
              label: 'Galería',
              onTap: data.onGalleryTap!,
            ),
          ),
        ],
      );
    }

    if (_directCapture && data.photos.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.photos.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildPhotoItem(context, data.photos[index], index);
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: data.onCameraTap,
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.black87,
                  ),
                  label: const Text('Otra con cámara'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: data.onGalleryTap,
                  icon: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.black87,
                  ),
                  label: const Text('Desde galería'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final showAddAside = !data.isReadOnly || data.showAddAsideInView;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAddAside) ...[_buildAddButton(), const SizedBox(width: 15)],
        Expanded(
          child: SizedBox(
            height: 140,
            child: data.photos.isEmpty && showAddAside
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _buildCameraPlaceholder(),
                  )
                : data.photos.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 140,
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFD9D9D9)),
                      ),
                      child: Text(
                        'Sin fotos',
                        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                          color: const Color(0xFF999A9D),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.photos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 15),
                    itemBuilder: (context, index) {
                      return _buildPhotoItem(
                        context,
                        data.photos[index],
                        index,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSinFotoGalleryRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.photos.isNotEmpty)
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildPhotoItem(context, data.photos[index], index),
              ),
            ),
          ),
        if (data.photos.isNotEmpty) const SizedBox(width: 12),
        _sinFotoTile(),
        const SizedBox(width: 12),
        Expanded(child: _galleryTile()),
      ],
    );
  }

  Widget _sinFotoTile() {
    final hasPhotos = data.photos.isNotEmpty;
    return Container(
      width: 100,
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasPhotos ? const Color(0xFFF5F5F5) : const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasPhotos ? const Color(0xFFD9D9D9) : const Color(0xFFCCCCCC),
        ),
      ),
      child: Text(
        'Sin foto',
        textAlign: TextAlign.center,
        style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
          fontSize: 13,
          color: const Color(0xFF999A9D),
        ),
      ),
    );
  }

  Widget _galleryTile() {
    final enabled = data.onGalleryTap != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: enabled ? data.onGalleryTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_rounded,
                size: 40,
                color: enabled ? Colors.black87 : Colors.black26,
              ),
              const SizedBox(height: 8),
              Text(
                'Galería',
                style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                  fontSize: 14,
                  color: enabled ? Colors.black87 : Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _captureTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCCCCC)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: Colors.black87),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: data.onAddPhotoTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFCCCCCC)),
          ),
          child: Center(
            child: SvgPicture.asset(
              AppIcons.unicoPacienteCamera,
              width: 48,
              height: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: data.onAddPhotoTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFCCCCCC)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppIcons.unicoPacienteAdd,
                width: 48,
                height: 48,
              ),
              const SizedBox(height: 10),
              Text(
                'Añadir\nimagen',
                textAlign: TextAlign.center,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, String imagePath, int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _viewFullScreen(context, imagePath),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(File(imagePath), fit: BoxFit.cover),
            ),
          ),
        ),
        if (!data.isReadOnly)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => data.onRemovePhotoTap(index),
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

  void _viewFullScreen(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: Image.file(File(imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
