import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/geo/nominatim_reverse_geocode.dart';
import 'package:sistema_triage/core/ui/app_snackbar.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/services/incident_location_service.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

typedef PlaceLookup = Future<String?> Function(double lat, double lng);

/// Modal flotante para elegir o revisar la ubicación del incidente
/// (B06 · Ajustar ubicación). El pin queda fijo en el centro del mapa: el punto
/// elegido es el centro, y el panel inferior muestra su dirección
class IncidentLocationMapDialog extends StatefulWidget {
  const IncidentLocationMapDialog({
    super.key,
    required this.initial,
    this.readOnly = false,
    this.title = 'Ubicación del incidente',
    this.placeLabel,
    this.placeLookup,
  });

  final LatLng initial;

  /// Solo ver: mapa fijo, sin «Centrar» ni botón de confirmar
  final bool readOnly;

  /// Encabezado en modo solo ver
  final String title;

  /// Dirección ya conocida de [initial]; si falta, se busca al abrir
  final String? placeLabel;

  /// Búsqueda de dirección; por defecto Nominatim
  final PlaceLookup? placeLookup;

  static Future<LatLng?> show(
    BuildContext context, {
    required double lat,
    required double lng,
    String? placeLabel,
  }) {
    return showDialog<LatLng>(
      context: context,
      builder: (ctx) => IncidentLocationMapDialog(
        initial: LatLng(lat, lng),
        placeLabel: placeLabel,
      ),
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
  /// Zoom al abrir el mapa
  static const double _zoomDefault = 16;

  /// Zoom al pulsar «Centrar»: más cercano para reconocer calles y referencias
  static const double _zoomGps = 19;

  /// Alto del modal respecto a la pantalla
  static const double _heightFactor = 0.82;

  /// Con texto grande el panel y la tarjeta de arriba tienen tope (y se
  /// desplazan por dentro): el mapa sigue usable
  static const double _panelMaxFactor = 0.5;
  static const double _headerMaxFactor = 0.3;

  /// Espera tras soltar el mapa antes de buscar la dirección: no se busca
  /// mientras se mueve. El segundo entre peticiones lo asegura
  /// [NominatimReverseGeocode]
  static const Duration _lookupDelay = Duration(milliseconds: 700);

  /// «Centrar», a la altura de Figma: algo por debajo del pin
  static const _centerButtonAlignment = AlignmentDirectional(1, 0.45);

  late LatLng _picked = widget.initial;
  late String? _place = widget.placeLabel;
  late bool _searchingPlace = widget.placeLabel == null;
  late final PlaceLookup _lookup =
      widget.placeLookup ?? NominatimReverseGeocode.shortPlaceLabel;
  final MapController _mapController = MapController();
  bool _loadingGps = false;
  Timer? _lookupTimer;
  int _lookupRequest = 0;

  @override
  void initState() {
    super.initState();
    if (_searchingPlace) unawaited(_lookupPlace());
  }

  @override
  void dispose() {
    _lookupTimer?.cancel();
    _lookupRequest++; // la búsqueda pendiente ya no aplica
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final c = camera.center;
    // Un centro no válido nunca debe poder confirmarse ni guardarse
    if (!c.latitude.isFinite || !c.longitude.isFinite) return;
    // Menos de ~1 cm: redondeo de la cámara, no un punto nuevo
    if ((_picked.latitude - c.latitude).abs() < 1e-7 &&
        (_picked.longitude - c.longitude).abs() < 1e-7) {
      return;
    }
    _lookupTimer?.cancel();
    _lookupRequest++;
    setState(() {
      _picked = c;
      _searchingPlace = true;
    });
    _lookupTimer = Timer(_lookupDelay, () => unawaited(_lookupPlace()));
  }

  /// Solo se aplica la respuesta del último punto
  Future<void> _lookupPlace() async {
    final request = ++_lookupRequest;
    final label = await _lookup(_picked.latitude, _picked.longitude);
    if (!mounted || request != _lookupRequest) return;
    setState(() {
      _place = label;
      _searchingPlace = false;
    });
  }

  Future<void> _centerOnDevice(BuildContext context) async {
    setState(() => _loadingGps = true);
    try {
      final p = await IncidentLocationService.getCurrentPosition();
      if (!mounted) return;
      if (p != null) {
        _mapController.move(LatLng(p.lat, p.lng), _zoomGps);
      } else if (context.mounted) {
        showAppSnackBar(
          context,
          IncidentLocationService.errorMessageForNullResult()!,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.readOnly;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TriageSpacing.md,
        vertical: TriageSpacing.xxl,
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: TriageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TriageRadii.xxl),
      ),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * _heightFactor,
        // Su propio aviso: el de la pantalla de debajo queda tapado por el modal
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: TriageColors.surface,
            body: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _picked,
                            initialZoom: _zoomDefault,
                            onPositionChanged: readOnly
                                ? null
                                : _onPositionChanged,
                            interactionOptions: InteractionOptions(
                              flags: readOnly
                                  ? InteractiveFlag.none
                                  : InteractiveFlag.all &
                                        ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: const [TriageMapTiles()],
                        ),
                        IgnorePointer(
                          child: Center(
                            child: readOnly
                                ? TriagePlacePin(semanticLabel: widget.title)
                                : const TriagePlacePin(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(TriageSpacing.lg),
                            child: _HeaderCard(
                              maxHeight:
                                  constraints.maxHeight * _headerMaxFactor,
                              title: readOnly
                                  ? widget.title
                                  : 'Mueve el mapa para ajustar',
                              subtitle: readOnly
                                  ? null
                                  : 'El pin marca el punto del incidente',
                            ),
                          ),
                        ),
                        if (!readOnly)
                          Align(
                            alignment: _centerButtonAlignment,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: TriageSpacing.lg,
                              ),
                              child: _loadingGps
                                  ? const _CenterLoading()
                                  : TriageIconButton(
                                      icon: TriageIcons.target,
                                      tooltip: 'Centrar en mi ubicación',
                                      onPressed: () =>
                                          unawaited(_centerOnDevice(context)),
                                      variant: TriageIconButtonVariant.surface,
                                      diameter: TriageSizes.touchTarget,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _ConfirmPanel(
                    maxHeight: constraints.maxHeight * _panelMaxFactor,
                    address: _searchingPlace
                        ? 'Buscando dirección…'
                        : _place ?? 'Ubicación seleccionada',
                    coordinates:
                        '${_picked.latitude.toStringAsFixed(4)}, '
                        '${_picked.longitude.toStringAsFixed(4)}',
                    onConfirm: readOnly
                        ? null
                        : () => Navigator.pop(context, _picked),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta flotante de arriba: volver, y qué hacer en el mapa
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.maxHeight,
    required this.title,
    this.subtitle,
  });

  /// Si el texto no cabe, se desplaza dentro de la tarjeta
  final double maxHeight;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.circular(TriageRadii.xxl),
        boxShadow: TriageShadows.floating,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            TriageSpacing.sm,
            TriageSpacing.sm,
            TriageSpacing.lg,
            TriageSpacing.sm,
          ),
          child: Row(
            spacing: TriageSpacing.sm,
            children: [
              TriageIconButton(
                icon: TriageIcons.arrowLeft,
                tooltip: 'Volver',
                onPressed: () => Navigator.pop(context),
                diameter: TriageSizes.touchTargetCompact,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TriageTextStyles.labelMedium.copyWith(
                        color: TriageColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TriageTextStyles.bodySmall.copyWith(
                          color: TriageColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Centrar» mientras se lee el GPS: mismo círculo, con indicador de carga
class _CenterLoading extends StatelessWidget {
  const _CenterLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Buscando tu ubicación',
      child: SizedBox.square(
        dimension: TriageSizes.touchTarget,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: TriageColors.surface,
            shape: BoxShape.circle,
            boxShadow: TriageShadows.base,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TriageSpacing.md),
            child: CircularProgressIndicator(
              strokeWidth: TriageSizes.strokeStrong,
              color: context.triageRole.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel inferior: dirección y coordenadas del punto y, si se puede elegir,
/// el botón de confirmar
class _ConfirmPanel extends StatelessWidget {
  const _ConfirmPanel({
    required this.maxHeight,
    required this.address,
    required this.coordinates,
    required this.onConfirm,
  });

  /// Si el contenido no cabe, se desplaza dentro del panel
  final double maxHeight;
  final String address;
  final String coordinates;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TriageColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TriageRadii.xxl),
        ),
        boxShadow: TriageShadows.sheet,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TriageSpacing.xl,
            TriageSpacing.lg,
            TriageSpacing.xl,
            TriageSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TriageSpacing.md,
            children: [
              Semantics(
                liveRegion: true,
                child: Row(
                  spacing: TriageSpacing.sm,
                  children: [
                    TriageIcon(
                      TriageIcons.location,
                      size: TriageSizes.icon,
                      color: context.triageRole.accent,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address,
                            style: TriageTextStyles.labelLarge.copyWith(
                              color: TriageColors.textPrimary,
                            ),
                          ),
                          Text(
                            coordinates,
                            style: TriageTextStyles.bodySmall.copyWith(
                              color: TriageColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (onConfirm != null)
                TriageButton(
                  label: 'Confirmar esta ubicación',
                  onPressed: onConfirm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
