import 'package:flutter/material.dart';

class IncidentHeaderData {
  final String id;
  final String createdAtLabel;
  final String title;
  final double latitude;
  final double longitude;
  final String gpsCoordinates;
  final bool hasGps;
  final int redCount;
  final int yellowCount;
  final int greenCount;
  final int blackCount;
  final int totalPatients;
  final bool isEditable;
  final VoidCallback? onShowMapTap;
  final VoidCallback? onEditLocationTap;
  final VoidCallback? onEditTitleTap;

  const IncidentHeaderData({
    required this.id,
    required this.createdAtLabel,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.gpsCoordinates,
    required this.hasGps,
    required this.redCount,
    required this.yellowCount,
    required this.greenCount,
    required this.blackCount,
    required this.totalPatients,
    this.isEditable = true,
    this.onShowMapTap,
    this.onEditLocationTap,
    this.onEditTitleTap,
  });
}
