import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/start_triage/photo_capture_area_data.dart';

class PhotoCaptureAreaWidget extends StatelessWidget {
  final PhotoCaptureAreaData data;

  const PhotoCaptureAreaWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = data.photos.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Captura fotografía del paciente',
            textAlign: TextAlign.center,
            style: AppTextStyles.ESC_SemiBold_titleMedium.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 207.0,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1C1C),
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: (() {
              Widget contentWidget = _buildPhotosList(context);
              if (isEmpty) {
                contentWidget = _buildEmptyState();
              }
              return contentWidget;
            })(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: data.onAddPhotoTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: Color(0xFFB3B3B3),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Procure que el rostro del paciente así como estado sean visibles.',
            textAlign: TextAlign.center,
            style: AppTextStyles.ESC_Thin_bodyLarge.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosList(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: data.photos.length + 1,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: data.onAddPhotoTap,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'Añadir imagen',
                    style: AppTextStyles.ESC_Light_bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final photoIndex = index - 1;
        final photoPath = data.photos[photoIndex];

        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.9),
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(10),
                    child: InteractiveViewer(
                      child: Image.file(File(photoPath), fit: BoxFit.contain),
                    ),
                  ),
                );
              },
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(photoPath), fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => data.onRemovePhotoTap(photoIndex),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
