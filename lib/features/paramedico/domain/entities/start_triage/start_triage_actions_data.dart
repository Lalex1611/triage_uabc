import 'package:flutter/material.dart';

class StartTriageActionsData {
  final bool hasPhotos;
  final VoidCallback onCancelOrReturn;
  final VoidCallback onSkip;
  final VoidCallback onRegister;

  StartTriageActionsData({
    required this.hasPhotos,
    required this.onCancelOrReturn,
    required this.onSkip,
    required this.onRegister,
  });
}
