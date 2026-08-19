import 'package:flutter/material.dart';

class DetailsPhotoData {
  final List<String> photos;
  final bool isReadOnly;
  final VoidCallback onAddPhotoTap;
  final ValueChanged<int> onRemovePhotoTap;

  const DetailsPhotoData({
    required this.photos,
    required this.onAddPhotoTap,
    required this.onRemovePhotoTap,
    this.isReadOnly = true,
  });
}
