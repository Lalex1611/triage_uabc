import 'package:flutter/material.dart';

/// Botonera fija inferior del registro sin traslado (mockups 07 y 08)
class MedicoWalkInBottomBarData {
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  const MedicoWalkInBottomBarData({
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondaryTap,
  });
}
