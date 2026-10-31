import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

// Pestaña Mapa de la vista de detalles de incidente
class IncidentDetailsMapTab extends StatelessWidget {
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onOpenInteractiveMap;

  const IncidentDetailsMapTab({
    super.key,
    required this.hasLocation,
    required this.latitude,
    required this.longitude,
    this.onOpenInteractiveMap,
  });

  @override
  Widget build(BuildContext context) {
    final lat = latitude;
    final lng = longitude;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 520.0;
        final mapHeight = (availableHeight - 88).clamp(320.0, 520.0).toDouble();

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(bottom: context.bottomNavExtent + 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: mapHeight,
                child: hasLocation && lat != null && lng != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'sistema_triage',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 44,
                                    height: 44,
                                    point: LatLng(lat, lng),
                                    alignment: Alignment.bottomCenter,
                                    child: const TriageIcon(
                                      TriageIcons.location,
                                      color: TriageColors.paramedicAccent,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Este incidente no tiene coordenadas registradas.\nUse Editar en el encabezado para fijar la ubicación.',
                            textAlign: TextAlign.center,
                            style: TriageTextStyles.bodyMedium.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: TriageButton(
                      label: 'MAPA INTERACTIVO',
                      variant: TriageButtonVariant.secondary,
                      size: TriageButtonSize.medium,
                      onPressed: hasLocation ? onOpenInteractiveMap : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
