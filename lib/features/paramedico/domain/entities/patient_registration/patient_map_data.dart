import 'package:flutter/material.dart';

/// Punto del paciente en registro/detalle; acciones delegadas al orquestador
class PatientMapData {
  final double latitude;
  final double longitude;
  final String sectionTitle;
  final VoidCallback? onOpenAppMapTap;
  final VoidCallback? onOpenGoogleMapsTap;
  final VoidCallback? onTriangulateTap;
  final bool showTriangulationButton;

  const PatientMapData({
    required this.latitude,
    required this.longitude,
    this.sectionTitle = 'Ubicación del paciente',
    this.onOpenAppMapTap,
    this.onOpenGoogleMapsTap,
    this.onTriangulateTap,
    this.showTriangulationButton = true,
  });
}
