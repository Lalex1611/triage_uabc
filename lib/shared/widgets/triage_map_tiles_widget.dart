import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';

/// Fondo de los mapas del rediseño: OpenStreetMap en gris claro, para que resalten
/// los marcadores, con la atribución que exige su licencia
///
/// Va como primer hijo de `FlutterMap`.
///
/// shortcut: filtro sobre el mapa estándar; para el estilo exacto de Figma hace
/// falta un proveedor de mapas vectoriales, que se cambiaría solo aquí.
class TriageMapTiles extends StatelessWidget {
  const TriageMapTiles({super.key});

  // Pasa a escala de grises (Rec. 709) y aclara un 15 %
  static const _lightGray = ColorFilter.matrix([
    0.181, 0.608, 0.061, 0, 38, //
    0.181, 0.608, 0.061, 0, 38, //
    0.181, 0.608, 0.061, 0, 38, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: _lightGray,
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'sistema_triage',
          ),
        ),
        // SimpleAttributionWidget se desborda con texto grande en pantallas estrechas
        Align(
          alignment: Alignment.bottomRight,
          child: ColoredBox(
            color: TriageColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(TriageSpacing.xxs),
              child: Text(
                '© OpenStreetMap contributors',
                style: TriageTextStyles.labelSmall.copyWith(
                  color: TriageColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
