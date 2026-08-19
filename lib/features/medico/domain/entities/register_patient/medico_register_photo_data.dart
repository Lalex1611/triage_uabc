import 'package:flutter/foundation.dart';

@immutable
class MedicoRegisterPhotoData {
  final List<String> photos;
  final bool isReadOnly;
  final VoidCallback onCameraTap;
  final VoidCallback onAddImageTap;
  final ValueChanged<int> onRemovePhotoTap;

  const MedicoRegisterPhotoData({
    required this.photos,
    required this.onCameraTap,
    required this.onAddImageTap,
    required this.onRemovePhotoTap,
    this.isReadOnly = false,
  });
}
