import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/triage_catalog.dart';

class PatientHeaderData {
  /* / ID del paciente. Ej: "PAC-28321". */
  final String patientId;

  // / Nombre del paciente. Si está vacío, se mostrará el placeholder "Nombre... (Opcional)"
  final String? patientName;

  /* / Coordenadas GPS del paciente. Ej: "19.4326, -99.1332". */
  final String gpsCoordinates;

  /* / Indica si el GPS ya fue capturado exitosamente. */
  final bool isGpsCaptured;

  /* / Categoría START elegida; null = cabecera roja paramédico hasta que el usuario elija. */
  final TriageCategory? triageCategory;

  /* / Callback para el botón "Mostrar" (mapa inline). */
  final VoidCallback onShowMapTap;

  /* / Abre el mapa para colocar el punto (mismo flujo que al crear el incidente). */
  final VoidCallback onEditLocationTap;

  /* / Callback para el botón "Generar Código de Consulta QR". */
  final VoidCallback onGenerateQrTap;

  /* / Estado visual del botón QR. Si es false, el tap conserva el feedback explicativo. */
  final bool isQrEnabled;

  /* / Etiqueta del botón QR. */
  final String qrButtonLabel;

  /* / Callback cuando el usuario edita el nombre del paciente. */
  final ValueChanged<String> onNameChanged;

  const PatientHeaderData({
    required this.patientId,
    required this.gpsCoordinates,
    required this.isGpsCaptured,
    required this.triageCategory,
    required this.onShowMapTap,
    required this.onEditLocationTap,
    required this.onGenerateQrTap,
    required this.onNameChanged,
    this.patientName,
    this.isQrEnabled = true,
    this.qrButtonLabel = 'Generar\nCódigo QR',
  });
}
