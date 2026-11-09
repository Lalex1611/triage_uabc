import 'package:flutter/material.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Hoja de "Más opciones" del incidente, para quien lo creó
void showIncidentMoreActions(
  BuildContext context, {
  required String title,
  required VoidCallback onEditTitle,
  required VoidCallback onEditLocation,
  required VoidCallback onAddPhotos,
  VoidCallback? onCloseIncident,
}) {
  showTriageSheet<void>(
    context,
    title: title,
    subtitle: 'Acciones disponibles para el responsable.',
    showClose: false,
    builder: (sheetContext) {
      VoidCallback closeThen(VoidCallback action) => () {
        Navigator.pop(sheetContext);
        action();
      };

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TriageOptionRow(
            icon: TriageIcons.pencil,
            title: 'Editar título',
            detail: 'Cambia el nombre con el que se identifica',
            onTap: closeThen(onEditTitle),
          ),
          TriageOptionRow(
            icon: TriageIcons.location,
            title: 'Editar ubicación',
            detail: 'Ajusta el punto del incidente en el mapa',
            onTap: closeThen(onEditLocation),
          ),
          TriageOptionRow(
            icon: TriageIcons.image,
            title: 'Añadir fotografías',
            detail: 'Documenta la escena',
            onTap: closeThen(onAddPhotos),
          ),
          if (onCloseIncident != null)
            TriageOptionRow(
              icon: TriageIcons.reject,
              title: 'Cerrar incidente',
              detail: 'Se retira de la lista de activos',
              onTap: closeThen(onCloseIncident),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TriageSpacing.xl,
              TriageSpacing.sm,
              TriageSpacing.xl,
              TriageSpacing.lg,
            ),
            child: TriageButton(
              label: 'Cerrar',
              variant: TriageButtonVariant.secondary,
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ),
        ],
      );
    },
  );
}
