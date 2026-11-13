import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Abre el panel "Capas del mapa" (Figma B01). Los interruptores cambian el
/// mapa al momento, sin esperar a cerrar.
///
/// Se abre en el navegador raíz para quedar por delante de la barra de
/// navegación del shell, que flota sobre la rama del mapa.
Future<void> showMapLayersSheet(
  BuildContext context,
  ParamedicoMapController controller,
) {
  return showTriageSheet<void>(
    Navigator.of(context, rootNavigator: true).context,
    title: 'Capas del mapa',
    subtitle: 'Decide qué se dibuja encima.',
    showClose: false,
    builder: (sheetContext) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TriageOptionRow.toggle(
            icon: TriageIcons.alert,
            title: 'Incidentes activos',
            detail: 'Marcadores con el total de pacientes',
            value: controller.showIncidents,
            onChanged: controller.setShowIncidents,
          ),
          TriageOptionRow.toggle(
            icon: TriageIcons.hospital,
            title: 'Hospitales receptores',
            detail: 'Solo los que están activos',
            value: controller.showHospitals,
            onChanged: controller.setShowHospitals,
          ),
          // Sin datos todavía: visibles pero desactivadas
          TriageOptionRow.toggle(
            icon: TriageIcons.ambulance,
            title: 'Unidades en servicio',
            detail: 'Ambulancias de tu base',
            value: false,
            onChanged: null,
          ),
          TriageOptionRow.toggle(
            icon: TriageIcons.map,
            title: 'Tráfico en tiempo real',
            detail: 'Útil para estimar la ruta',
            value: false,
            onChanged: null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TriageSpacing.xl,
              TriageSpacing.sm,
              TriageSpacing.xl,
              TriageSpacing.xl,
            ),
            child: TriageButton(
              label: 'Cerrar',
              variant: TriageButtonVariant.secondary,
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ),
        ],
      ),
    ),
  );
}
