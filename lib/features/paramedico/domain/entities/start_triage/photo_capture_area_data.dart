import 'package:flutter/material.dart';

class PhotoCaptureAreaData {
  final List<String> photos; // Rutas o identifiers de las fotos
  final VoidCallback onAddPhotoTap;
  final Function(int index) onRemovePhotoTap;

  PhotoCaptureAreaData({
    required this.photos,
    required this.onAddPhotoTap,
    required this.onRemovePhotoTap,
  });
}
