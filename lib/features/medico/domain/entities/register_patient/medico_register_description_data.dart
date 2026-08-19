import 'package:flutter/foundation.dart';

@immutable
class MedicoRegisterDescriptionData {
  final String descriptionText;
  final bool isReadOnly;
  final ValueChanged<String> onDescriptionChanged;

  const MedicoRegisterDescriptionData({
    required this.onDescriptionChanged,
    this.descriptionText = '',
    this.isReadOnly = false,
  });
}
