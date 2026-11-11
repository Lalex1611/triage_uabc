import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/emergency_catalog.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_controller.dart';
import 'package:sistema_triage/shared/widgets/triage_icon_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_map_markers_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_map_tiles_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_tap_card_widget.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';

/// Abre la hoja "Nuevo incidente" sobre la pantalla actual
///
/// Al crear el incidente cierra la hoja y abre el mapa enfocado en él.
Future<void> showCreateIncidentSheet(BuildContext context) async {
  final createdId = await showTriageSheet<String>(
    context,
    title: 'Nuevo incidente',
    // Formulario a medias: no se cierra arrastrando ni tocando fuera
    dismissible: false,
    builder: (_) => const _CreateIncidentBody(),
  );
  if (createdId != null && context.mounted) {
    context.go('/paramedico/mapa?focus=$createdId');
  }
}

class _CreateIncidentBody extends StatefulWidget {
  const _CreateIncidentBody();

  @override
  State<_CreateIncidentBody> createState() => _CreateIncidentBodyState();
}

class _CreateIncidentBodyState extends State<_CreateIncidentBody> {
  // Proporción del alto disponible que ocupa la hoja
  static const double _heightFactor = 0.9;
  // Proporción ancho/alto de la vista previa del mapa
  static const double _mapAspectRatio = 2.2;
  static const double _mapZoom = 15;
  static const int _photoColumns = 3;

  static const List<String> _quickTags = [
    'Volcadura',
    'Vía bloqueada',
    'Fuga de combustible',
    'Atrapados',
    'Menores',
  ];

  late final CreateIncidentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateIncidentController();
    _controller.addListener(_onController);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.refreshGpsFromDevice(context, silent: true);
      if (mounted) await _controller.refreshPreviewTitle();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final id = await _controller.submit(context);
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    // Si sube el teclado, la hoja se acorta para que la barra de abajo siga visible
    final available =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;

    return SizedBox(
      height: available * _heightFactor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(TriageSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: TriageSpacing.xxl,
                children: [
                  _typeSection(c),
                  _locationSection(c),
                  _detailsSection(c),
                ],
              ),
            ),
          ),
          TriageActionBar(
            secondary: TriageButton(
              label: 'Cancelar',
              variant: TriageButtonVariant.secondary,
              onPressed: c.submitting
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
            primary: TriageButton(
              label: 'Crear incidente',
              isLoading: c.submitting,
              onPressed: c.submitting ? null : () => unawaited(_create()),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1 · Tipo de emergencia
  // ---------------------------------------------------------------------------

  Widget _typeSection(CreateIncidentController c) {
    final tiles = [
      for (final type in EmergencyCatalog.standardTypes)
        _EmergencyTile(
          icon: _iconFor(type.id),
          label: type.name,
          selected: type.id == c.emergencyTypeId,
          onTap: () => c.setEmergencyType(type.id),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TriageSpacing.md,
      children: [
        const _NumberedHeading(
          number: 1,
          title: '¿Qué tipo de emergencia es?',
          subtitle: 'Toca una opción. Puedes cambiarla después.',
        ),
        // Dos columnas; cada fila toma el alto de la tarjeta más alta
        for (var i = 0; i < tiles.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TriageSpacing.md,
              children: [
                Expanded(child: tiles[i]),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _iconFor(String id) => switch (id.toLowerCase()) {
    'accidente_vehicular' => TriageIcons.alert,
    'atropellamiento' => TriageIcons.walk,
    'caida' => TriageIcons.arrowDown,
    'violencia' => TriageIcons.shield,
    'incendio_quemadura' => TriageIcons.thermometer,
    'emergencia_medica' => TriageIcons.heart,
    'derrumbe' => TriageIcons.layers,
    'otro' => TriageIcons.plus,
    _ => TriageIcons.alert,
  };

  // ---------------------------------------------------------------------------
  // 2 · Ubicación
  // ---------------------------------------------------------------------------

  Widget _locationSection(CreateIncidentController c) {
    final searching = c.refreshingGps || c.refreshingTitle;
    final place = searching ? null : _placeFromTitle(c.previewTitle);
    final address = searching
        ? 'Buscando dirección…'
        : (place ?? 'Ubicación seleccionada');
    final coordinates =
        '${c.lat.toStringAsFixed(4)}, ${c.lng.toStringAsFixed(4)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TriageSpacing.md,
      children: [
        const _NumberedHeading(
          number: 2,
          title: '¿Dónde ocurrió?',
          subtitle: 'El GPS ya tomó tu posición. Ajústala si no coincide.',
        ),
        TriageSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TriageSpacing.md,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(TriageRadii.lg),
                child: AspectRatio(
                  aspectRatio: _mapAspectRatio,
                  // Solo vista previa: no captura los gestos del scroll
                  child: IgnorePointer(
                    child: FlutterMap(
                      // Se reconstruye al cambiar la posición
                      key: ValueKey((c.lat, c.lng)),
                      options: MapOptions(
                        initialCenter: LatLng(c.lat, c.lng),
                        initialZoom: _mapZoom,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        const TriageMapTiles(),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(c.lat, c.lng),
                              width: TriageSizes.touchTarget,
                              height: TriageSizes.touchTarget,
                              child: const TriageUserMarker(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
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
                  TriageSectionAction(
                    label: 'Ajustar',
                    onTap: () => unawaited(c.openLocationMap(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// La dirección sale del título automático ("18-marzo-2026 14:32-Blvd. X");
  /// si solo hay coordenadas, devuelve null
  static String? _placeFromTitle(String title) {
    final match = RegExp(
      r'^\d{1,2}-[^-]+-\d{4} \d{2}:\d{2}-(.+)$',
    ).firstMatch(title);
    final place = match?.group(1)?.trim();
    if (place == null || place.isEmpty) return null;
    if (RegExp(r'^-?\d+\.\d+, -?\d+\.\d+$').hasMatch(place)) return null;
    return place;
  }

  // ---------------------------------------------------------------------------
  // 3 · Detalles (opcional)
  // ---------------------------------------------------------------------------

  Widget _detailsSection(CreateIncidentController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TriageSpacing.md,
      children: [
        const _NumberedHeading(
          number: 3,
          title: 'Detalles (opcional)',
          subtitle: 'Puedes crear el incidente sin esto y completarlo después.',
        ),
        TriageSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TriageSpacing.lg,
            children: [
              GridView.count(
                crossAxisCount: _photoColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: TriageSpacing.sm,
                crossAxisSpacing: TriageSpacing.sm,
                children: [
                  TriagePhoto(
                    onTap: () => c.showImageSourceDialog(context),
                  ),
                  for (var i = 0; i < c.photos.length; i++)
                    TriagePhoto(
                      image: FileImage(File(c.photos[i])),
                      onTap: () => unawaited(_openPhotoMenu(i)),
                    ),
                ],
              ),
              TriageField.area(
                label: 'Descripción',
                hint: 'Escribe lo que ves en la escena…',
                controller: c.descriptionController,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: TriageSpacing.sm,
                children: [
                  Text(
                    'Agrega detalles rápidos',
                    style: TriageTextStyles.labelMedium.copyWith(
                      color: TriageColors.textSecondary,
                    ),
                  ),
                  Wrap(
                    spacing: TriageSpacing.sm,
                    runSpacing: TriageSpacing.sm,
                    children: [
                      for (final tag in _quickTags)
                        TriageChip(
                          label: '+ $tag',
                          selected: false,
                          onTap: () => _addTag(c, tag),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Agrega la palabra al final de la descripción, separada por comas, sin repetirla
  void _addTag(CreateIncidentController c, String tag) {
    final controller = c.descriptionController;
    final text = controller.text.trim();
    final existing = text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty);
    if (existing.contains(tag.toLowerCase())) return;

    final next = text.isEmpty
        ? tag
        : (text.endsWith(',') ? '$text $tag' : '$text, $tag');
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _openPhotoMenu(int index) async {
    final remove = await showTriageSheet<bool>(
      context,
      title: 'Fotografía',
      builder: (sheetContext) => ListTile(
        onTap: () => Navigator.pop(sheetContext, true),
        leading: const TriageIcon(
          TriageIcons.trash,
          size: TriageSizes.icon,
          color: TriageColors.textSecondary,
        ),
        title: Text(
          'Quitar fotografía',
          style: TriageTextStyles.bodyMedium.copyWith(
            color: TriageColors.textPrimary,
          ),
        ),
      ),
    );
    if (remove == true && mounted) _controller.removePhotoAt(index);
  }
}

/// Encabezado de sección con círculo numerado, título y una línea de ayuda
class _NumberedHeading extends StatelessWidget {
  const _NumberedHeading({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final int number;
  final String title;
  final String subtitle;

  static const double _badge = 24;

  @override
  Widget build(BuildContext context) {
    final role = context.triageRole;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: TriageSpacing.xs,
      children: [
        Row(
          spacing: TriageSpacing.sm,
          children: [
            SizedBox.square(
              dimension: context.rDim(_badge),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: role.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$number',
                      style: TriageTextStyles.labelSmall.copyWith(
                        color: TriageColors.textInverse,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TriageTextStyles.titleSmall.copyWith(
                    color: TriageColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          subtitle,
          style: TriageTextStyles.bodySmall.copyWith(
            color: TriageColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de tipo de emergencia: ícono arriba, nombre debajo; seleccionada,
/// toma el color del rol con una palomita
class _EmergencyTile extends StatelessWidget {
  const _EmergencyTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = context.triageRole;
    final color = selected ? role.accent : TriageColors.textPrimary;

    return TriageTapCard(
      onTap: onTap,
      selected: selected,
      color: selected ? role.soft : TriageColors.surface,
      borderColor: selected ? role.accent : TriageColors.borderMedium,
      borderWidth: selected ? TriageSizes.strokeStrong : TriageSizes.stroke,
      shadow: TriageShadows.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: TriageSpacing.md,
        children: [
          Row(
            children: [
              TriageIcon(icon, size: TriageSizes.icon, color: color),
              const Spacer(),
              if (selected)
                TriageIcon(
                  TriageIcons.checkCircle,
                  size: TriageSizes.icon,
                  color: role.accent,
                ),
            ],
          ),
          Text(
            label,
            style: TriageTextStyles.labelLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}