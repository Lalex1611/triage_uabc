import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

typedef GpsStatus = ({
  bool serviceEnabled,
  bool isGranted,
  bool isPermanentlyDenied,
});

/// Obtiene la posición GPS, gestiona permisos y muestra su estado en UI
class IncidentLocationService {
  IncidentLocationService._();

  /// Abre el panel flotante para revisar, solicitar o probar el permiso de GPS
  static Future<void> showPermissionsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: TriageColors.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (_) => const _GpsPermissionsSheet(),
    );
  }

  /// Consulta si el GPS del dispositivo está encendido y si la app tiene permiso
  static Future<GpsStatus> checkStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          serviceEnabled: false,
          isGranted: false,
          isPermanentlyDenied: false,
        );
      }

      final permission = await Geolocator.checkPermission();
      final isGranted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      final isPermanentlyDenied =
          permission == LocationPermission.deniedForever;

      return (
        serviceEnabled: true,
        isGranted: isGranted,
        isPermanentlyDenied: isPermanentlyDenied,
      );
    } catch (_) {
      return (
        serviceEnabled: false,
        isGranted: false,
        isPermanentlyDenied: false,
      );
    }
  }

  /// Solicita el permiso o abre los ajustes del sistema según el estado actual
  static Future<GpsStatus> requestOrOpenSettings() async {
    final current = await checkStatus();

    if (!current.serviceEnabled) {
      await Geolocator.openLocationSettings();
      return checkStatus();
    }

    if (current.isPermanentlyDenied) {
      await Geolocator.openAppSettings();
      return checkStatus();
    }

    if (!current.isGranted) {
      await Geolocator.requestPermission();
      return checkStatus();
    }

    return current;
  }

  /// Obtiene las coordenadas actuales si el GPS está activo y con permisos
  static Future<({double lat, double lng})?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  static String? errorMessageForNullResult() {
    return 'No se pudo obtener la ubicación. Activa el GPS y concede permiso a la app.';
  }
}

class _GpsPermissionsSheet extends StatefulWidget {
  const _GpsPermissionsSheet();

  @override
  State<_GpsPermissionsSheet> createState() => _GpsPermissionsSheetState();
}

class _GpsPermissionsSheetState extends State<_GpsPermissionsSheet>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _testingSignal = false;
  GpsStatus _status = (
    serviceEnabled: false,
    isGranted: false,
    isPermanentlyDenied: false,
  );
  String? _signalFeedback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final next = await IncidentLocationService.checkStatus();
    if (!mounted) return;
    setState(() {
      _status = next;
      _checking = false;
    });
  }

  String get _statusTitle {
    if (_checking) return 'Verificando GPS...';
    if (!_status.serviceEnabled) return 'GPS del dispositivo apagado';
    if (_status.isGranted) return 'Ubicación GPS activa';
    if (_status.isPermanentlyDenied) return 'Permiso bloqueado en ajustes';
    return 'Permiso de ubicación pendiente';
  }

  String get _statusSubtitle {
    if (_checking) return 'Consultando estado de ubicación en el equipo.';
    if (!_status.serviceEnabled) {
      return 'Activa la ubicación del teléfono para georreferenciar incidentes y pacientes.';
    }
    if (_status.isGranted) {
      return _signalFeedback ??
          'Listo para capturar coordenadas en incidentes, evaluaciones y traslados.';
    }
    if (_status.isPermanentlyDenied) {
      return 'Habilita el acceso a la ubicación desde la configuración del sistema.';
    }
    return 'Concede acceso al GPS para registrar la ubicación exacta de atención.';
  }

  String get _actionLabel {
    if (!_status.serviceEnabled) return 'Activar GPS del teléfono';
    if (_status.isPermanentlyDenied) return 'Abrir configuración';
    if (!_status.isGranted) return 'Permitir ubicación GPS';
    return _testingSignal ? 'Obteniendo coordenadas...' : 'Probar señal GPS';
  }

  Future<void> _handleAction() async {
    if (!_status.isGranted) {
      final updated = await IncidentLocationService.requestOrOpenSettings();
      if (!mounted) return;
      setState(() => _status = updated);
      return;
    }

    setState(() => _testingSignal = true);
    final coords = await IncidentLocationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _testingSignal = false;
      _signalFeedback = coords != null
          ? 'Señal confirmada (${coords.lat.toStringAsFixed(5)}, ${coords.lng.toStringAsFixed(5)})'
          : IncidentLocationService.errorMessageForNullResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isReady = _status.isGranted;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TriageSpacing.md,
        TriageSpacing.md,
        TriageSpacing.md,
        bottomInset + TriageSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TriageSpacing.lg,
          TriageSpacing.md,
          TriageSpacing.lg,
          TriageSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: TriageColors.surface,
          borderRadius: BorderRadius.circular(TriageRadii.xxl),
          boxShadow: TriageShadows.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: TriageColors.borderMedium,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: TriageSpacing.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TriageColors.paramedicAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: TriageColors.paramedicAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: TriageSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacidad y permisos',
                        style: TriageTextStyles.titleMedium.copyWith(
                          color: TriageColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Control de ubicación en turno',
                        style: TriageTextStyles.bodySmall.copyWith(
                          color: TriageColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TriageIconButton(
                  icon: TriageIcons.close,
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  variant: TriageIconButtonVariant.plain,
                  iconSize: TriageSizes.iconLarge,
                ),
              ],
            ),
            const SizedBox(height: TriageSpacing.md),
            const Divider(
              height: TriageSizes.hairline,
              thickness: TriageSizes.hairline,
              color: TriageColors.borderSubtle,
            ),
            const SizedBox(height: TriageSpacing.md),
            Container(
              padding: const EdgeInsets.all(TriageSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(TriageRadii.md + 2),
                border: Border.all(color: TriageColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusTitle,
                          style: TriageTextStyles.titleSmall.copyWith(
                            color: TriageColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TriageSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isReady
                                      ? Colors.green.shade700
                                      : TriageColors.paramedicAccent)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _checking
                              ? '...'
                              : (isReady ? 'Activo' : 'Requiere acción'),
                          style: TriageTextStyles.labelSmall.copyWith(
                            color: isReady
                                ? Colors.green.shade800
                                : TriageColors.paramedicAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TriageSpacing.xs),
                  Text(
                    _statusSubtitle,
                    style: TriageTextStyles.bodySmall.copyWith(
                      color: TriageColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TriageSpacing.md),
            Text(
              'La ubicación se consulta únicamente al crear incidentes, capturar pacientes o iniciar un traslado hospitalario.',
              style: TriageTextStyles.bodySmall.copyWith(
                color: TriageColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: TriageSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: TriageColors.paramedicAccent,
                  foregroundColor: TriageColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    vertical: TriageSpacing.md + 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TriageRadii.md + 4),
                  ),
                  elevation: 0,
                ),
                onPressed: (_checking || _testingSignal) ? null : _handleAction,
                child: Text(
                  _actionLabel,
                  style: TriageTextStyles.titleSmall.copyWith(
                    color: TriageColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
