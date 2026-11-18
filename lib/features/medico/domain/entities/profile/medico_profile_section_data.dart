import 'package:flutter/material.dart';

/// Fila "etiqueta ........ valor" de una tarjeta del perfil (mockup 13)
class MedicoProfileRowData {
  final String label;
  final String value;

  const MedicoProfileRowData({required this.label, required this.value});
}

/// Tarjeta del perfil con título, acción opcional ("Editar") y filas
class MedicoProfileSectionData {
  final String title;
  final List<MedicoProfileRowData> rows;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final String? footnote;

  const MedicoProfileSectionData({
    required this.title,
    required this.rows,
    this.actionLabel,
    this.onActionTap,
    this.footnote,
  });
}
