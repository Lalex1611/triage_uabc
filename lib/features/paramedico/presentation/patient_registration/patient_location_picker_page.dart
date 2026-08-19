import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/constants/app_colors.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/patient_location_actions.dart';

// Pantalla aislada de mapa maximizado para elegir la ubicación del paciente
class PatientLocationPickerPage extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String title;

  const PatientLocationPickerPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.title = 'Ubicación del paciente',
  });

  @override
  State<PatientLocationPickerPage> createState() => _PatientLocationPickerPageState();
}

class _PatientLocationPickerPageState extends State<PatientLocationPickerPage> {
  static const double _zoomDefault = 16;
  static const double _zoomGps = 19;

  late LatLng _picked;
  final MapController _mapController = MapController();
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _picked = LatLng(widget.initialLat, widget.initialLng);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(_picked, _zoomDefault);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final s = camera.nonRotatedSize;
    if (s.width == 0 || s.height == 0) return;
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
      final ll = await PatientLocationActions.captureCurrentPosition(context);
      if (!mounted || ll == null) return;
      setState(() => _picked = ll);
      _mapController.move(ll, _zoomGps);
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryParamedico,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Arrastra el mapa para colocar el pin. Puedes usar tu ubicación actual.',
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _picked,
                    initialZoom: _zoomDefault,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        color: AppColors.primaryParamedico,
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
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryParamedico,
                    onPressed: _loadingGps ? null : _centerOnDevice,
                    child: _loadingGps
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${_picked.latitude.toStringAsFixed(6)}, ${_picked.longitude.toStringAsFixed(6)}',
              textAlign: TextAlign.center,
              style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loadingGps ? null : _centerOnDevice,
                    child: const Text('Ubicación actual'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryParamedico,
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
        ],
      ),
    );
  }
}
