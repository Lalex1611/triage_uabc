import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class DetailsAppBarData {
  final TriageCategory triageCategory;
  final VoidCallback onBackTap;
  final VoidCallback onCloseIncidentTap;
  final String? backLabel;

  const DetailsAppBarData({
    required this.triageCategory,
    required this.onBackTap,
    required this.onCloseIncidentTap,
    this.backLabel,
  });
}
