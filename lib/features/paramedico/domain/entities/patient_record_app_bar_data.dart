import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class PatientRecordAppBarData {
  final TriageCategory? triageCategory;
  final String backLabel;
  final VoidCallback onBackTap;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const PatientRecordAppBarData({
    required this.triageCategory,
    required this.backLabel,
    required this.onBackTap,
    this.actionLabel,
    this.onActionTap,
  });
}
