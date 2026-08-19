import 'package:flutter/material.dart';

class DetailsActionsData {
  final bool canEdit;
  final VoidCallback onCancelTap;
  final VoidCallback onSaveTap;

  const DetailsActionsData({
    required this.canEdit,
    required this.onCancelTap,
    required this.onSaveTap,
  });
}
