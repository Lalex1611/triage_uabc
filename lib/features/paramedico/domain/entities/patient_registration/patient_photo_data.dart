import 'package:flutter/material.dart';

class PatientPhotoData {
  /* / Lista de paths locales de las fotos capturadas. */
  final List<String> photos;

  /* / Callback al presionar el área de agregar foto (abre bottom sheet cámara/galería). */
  final VoidCallback onAddPhotoTap;

  /* / Si ambos están definidos, se muestran botones directos Cámara / Galería. */
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;

  /* / Callback al presionar el botón de eliminar una foto. */
  final Function(int) onRemovePhotoTap;
  final bool isReadOnly;

  /// En vista consulta: sin título; muestra fotos y botón «Añadir» al lado si aplica
  final bool showAddAsideInView;

  /// Fila «Sin foto» + «Galería» (detalle de paciente)
  final bool showSinFotoGalleryRow;

  const PatientPhotoData({
    required this.photos,
    required this.onAddPhotoTap,
    required this.onRemovePhotoTap,
    this.isReadOnly = false,
    this.showAddAsideInView = false,
    this.showSinFotoGalleryRow = false,
    this.onCameraTap,
    this.onGalleryTap,
  });
}
