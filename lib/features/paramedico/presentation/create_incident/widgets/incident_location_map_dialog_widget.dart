import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';

// Dialogo de mapa OSM para seleccionar o revisar la ubicacion del incidente
class IncidentLocationMapDialog extends StatefulWidget {
  const IncidentLocationMapDialog({
    super.key,
    required this.initial,
    this.readOnly = false,
    this.title = 'Ubicación del incidente',
  });

  final LatLng initial;
  final bool readOnly;
  final String title;

  static Future<LatLng?> show(
    BuildContext context, {
    required double lat,
    required double lng,
    String title = 'Ubicación del incidente',
  }) {
    return showDialog<LatLng>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) =>
          IncidentLocationMapDialog(initial: LatLng(lat, lng), title: title),
    );
  }

  /// Solo visualización: mapa fijo, sin elegir punto ni devolver coordenadas
  static Future<void> showPreview(
    BuildContext context, {
    required double lat,
    required double lng,
    String title = 'Ubicación',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => IncidentLocationMapDialog(
        initial: LatLng(lat, lng),
        readOnly: true,
        title: title,
      ),
    );
  }

  @override
  State<IncidentLocationMapDialog> createState() =>
      _IncidentLocationMapDialogState();
}

class _IncidentLocationMapDialogState extends State<IncidentLocationMapDialog> {
  /// Zoom al abrir el mapa o con coordenadas ya conocidas
  static const double _zoomDefault = 16;

  /// Zoom al pulsar «Mi ubicación (GPS)»: más cercano para reconocer calles y referencias
  static const double _zoomGps = 19;

  late LatLng _picked;
  final MapController _mapController = MapController();
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(_picked, _zoomDefault);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (widget.readOnly) return;
    final s = camera.nonRotatedSize;
    if (s.width == 0 || s.height == 0) return;
    // Punto del mapa bajo la punta del pin (icono centrado y desplazado hacia arriba)
    final tipScreen = Offset(s.width / 2, s.height / 2 + 4);
    final c = camera.screenOffsetToLatLng(tipScreen);
    if ((_picked.latitude - c.latitude).abs() < 1e-9 &&
        (_picked.longitude - c.longitude).abs() < 1e-9) {
      return;
    }
    setState(() => _picked = c);
  }

  Future<void> _centerOnDevice() async {
    setState(() => _loadingGps = true);
    try {
      final p = await IncidentLocationService.getCurrentPosition();
      if (!mounted) return;
      if (p != null) {
        final ll = LatLng(p.lat, p.lng);
        setState(() => _picked = ll);
        _mapController.move(ll, _zoomGps);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(IncidentLocationService.errorMessageForNullResult()!),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size.width,
        height: size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: const Color(0xFFCE1125),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  'El pin indica el punto. Arrastra el mapa para colocarlo; puedes acercar con gestos.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _picked,
                          initialZoom: _zoomDefault,
                          onPositionChanged: widget.readOnly
                              ? null
                              : _onPositionChanged,
                          interactionOptions: widget.readOnly
                              ? const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                )
                              : const InteractionOptions(),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'sistema_triage',
                          ),
                        ],
                      ),
                      IgnorePointer(
                        child: Align(
                          alignment: Alignment.center,
                          child: Transform.translate(
                            offset: const Offset(0, -22),
                            child: Icon(
                              Icons.location_pin,
                              size: 52,
                              color: const Color(0xFFCE1125),
                              shadows: const [
                                Shadow(
                                  blurRadius: 4,
                                  color: Color(0x66000000),
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Text(
                '${_picked.latitude.toStringAsFixed(6)}, ${_picked.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: widget.readOnly
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFCE1125),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loadingGps ? null : _centerOnDevice,
                            child: _loadingGps
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Mi ubicación (GPS)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFCE1125),
                            ),
                            onPressed: () => Navigator.pop(
                              context,
                              LatLng(_picked.latitude, _picked.longitude),
                            ),
                            child: const Text('Usar esta ubicación'),
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Mapa © OpenStreetMap contributors',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
