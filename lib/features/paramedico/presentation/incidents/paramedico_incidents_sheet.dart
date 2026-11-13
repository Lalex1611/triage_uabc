import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_triage/core/constants/triage_icons.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/core/theme/triage_role_theme.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/core/util/time_ago.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';
import 'package:sistema_triage/features/paramedico/domain/constants/incident_sorting_options.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/home/incident_for_cards.dart';
import 'package:sistema_triage/features/paramedico/domain/services/incident_list_query.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/incidents/paramedico_incidents_controller.dart';
import 'package:sistema_triage/shared/domain/triage_level.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abre la hoja de "Incidentes activos" (B02) sobre la pantalla actual
///
/// Altura fija (proporción de la pantalla): el encabezado y el buscador quedan
/// fijos y solo la lista se desplaza. La hoja se abre en el navegador de
/// [host] (por defecto [context]): el shell pasa el de la rama del mapa para
/// que la barra de navegación quede por delante, como en Figma. Lo que se abre
/// al elegir algo usa [context].
Future<void> showParamedicoIncidentsSheet(
  BuildContext context, {
  BuildContext? host,
}) async {
  final path = await showTriageSheet<String>(
    host ?? context,
    showClose: false,
    builder: (_) => const _IncidentsSheetBody(),
  );
  // La hoja devuelve la ruta elegida y la navegación ocurre ya con la hoja
  // cerrada, no en el mismo instante en que se cierra
  if (path != null && context.mounted) {
    if (path == '/paramedico/incident/nuevo') {
      await showCreateIncidentSheet(context);
    } else {
      pushParamedicoFullScreen(context, path);
    }
  }
}

class _IncidentsSheetBody extends StatefulWidget {
  const _IncidentsSheetBody();

  @override
  State<_IncidentsSheetBody> createState() => _IncidentsSheetBodyState();
}

class _IncidentsSheetBodyState extends State<_IncidentsSheetBody> {
  // Proporción del alto de pantalla que ocupa la hoja
  static const double _heightFactor = 0.85;

  late final ParamedicoIncidentsController _controller;
  bool _mineOnly = false;
  IncidentSortOption _sort = IncidentSortOption.recent;

  @override
  void initState() {
    super.initState();
    _controller = ParamedicoIncidentsController();
    _controller.addListener(_onController);
    unawaited(_controller.load());
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

  String get _uid => Supabase.instance.client.auth.currentUser?.id ?? '';

  List<ParamedicoIncidentSummary> get _visible =>
      IncidentListQuery.filterAndSort(
        incidents: _controller.items,
        countsByIncident: _controller.counts,
        searchQuery: _controller.searchQuery,
        mineOnly: _mineOnly,
        currentUserId: _uid,
        sortOption: _sort,
      );

  // Cierra la hoja devolviendo la ruta; quien la abrió navega después
  void _openFullScreen(String path) => Navigator.of(context).pop(path);

  Future<void> _pickSort() async {
    final choice = await showTriageSheet<IncidentSortOption>(
      context,
      title: 'Ordenar por',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in IncidentSortOption.values)
            _OptionTile(
              label: option.title,
              selected: option == _sort,
              onTap: () => Navigator.pop(sheetContext, option),
            ),
        ],
      ),
    );
    if (choice != null && mounted) setState(() => _sort = choice);
  }

  Future<void> _pickFilter() async {
    final choice = await showTriageSheet<bool>(
      context,
      title: 'Mostrar',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionTile(
            label: 'Todos los incidentes',
            selected: !_mineOnly,
            onTap: () => Navigator.pop(sheetContext, false),
          ),
          _OptionTile(
            label: 'Mis incidentes',
            selected: _mineOnly,
            onTap: () => Navigator.pop(sheetContext, true),
          ),
        ],
      ),
    );
    if (choice != null && mounted) setState(() => _mineOnly = choice);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.triageRole;
    final visible = _visible;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * _heightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TriageSpacing.xl,
              TriageSpacing.xs,
              TriageSpacing.xl,
              TriageSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: TriageSpacing.sm,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Incidentes activos',
                          style: TriageTextStyles.titleMedium.copyWith(
                            color: TriageColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TriageSpacing.sm,
                          vertical: TriageSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: role.soft,
                          borderRadius: BorderRadius.circular(TriageRadii.full),
                        ),
                        child: Text(
                          '${visible.length}',
                          style: TriageTextStyles.labelMedium.copyWith(
                            color: role.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TriageSpacing.sm),
                TriageIconButton(
                  icon: TriageIcons.sort,
                  tooltip: 'Ordenar',
                  onPressed: _pickSort,
                ),
                const SizedBox(width: TriageSpacing.sm),
                TriageIconButton(
                  icon: TriageIcons.filter,
                  tooltip: 'Filtrar',
                  onPressed: _pickFilter,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TriageSpacing.xl),
            child: TriageSearchBar(
              hint: 'Buscar por folio, calle o tipo',
              controller: _controller.searchController,
              onChanged: _controller.onSearchChanged,
            ),
          ),
          const SizedBox(height: TriageSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TriageSpacing.xl),
            child: SizedBox(
              width: double.infinity,
              child: TriageButton(
                label: 'Registrar nuevo incidente',
                onPressed: () => _openFullScreen('/paramedico/incident/nuevo'),
              ),
            ),
          ),
          const SizedBox(height: TriageSpacing.md),
          Expanded(child: _buildList(visible, role.accent)),
        ],
      ),
    );
  }

  Widget _buildList(List<ParamedicoIncidentSummary> visible, Color accent) {
    if (_controller.loading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    final error = _controller.error;
    final message =
        error ??
        (visible.isEmpty
            ? (_controller.items.isEmpty
                  ? 'No hay incidentes activos.'
                  : 'No hay incidentes con ese criterio.')
            : null);

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: message != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TriageSpacing.xl),
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TriageTextStyles.bodyMedium.copyWith(
                    color: TriageColors.textSecondary,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                TriageSpacing.xl,
                0,
                TriageSpacing.xl,
                TriageSpacing.xl,
              ),
              itemCount: visible.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: TriageSpacing.md),
              itemBuilder: (context, i) {
                final incident = visible[i];
                // card.id es el folio para mostrar (INC-XXXXXX), no el id real
                final card = _controller.toCard(incident, _uid);
                return TriageIncidentCard(
                  folio: card.id,
                  timeAgo: timeAgo(card.dateTime),
                  title: card.name_card,
                  location: _coordinates(card),
                  counts: {
                    TriageLevel.red: card.red,
                    TriageLevel.yellow: card.yellow,
                    TriageLevel.green: card.green,
                    TriageLevel.black: card.black,
                  },
                  patientCount: card.totalVictims,
                  onTap: () =>
                      _openFullScreen('/paramedico/incident/${incident.id}'),
                );
              },
            ),
    );
  }

  // Aún no hay dirección en los datos: se muestran las coordenadas
  static String _coordinates(IncidentForCards card) =>
      '${card.latitude.toStringAsFixed(4)}, ${card.longitude.toStringAsFixed(4)}';
}

/// Fila de opción de las hojas de ordenar y filtrar
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TriageTextStyles.bodyMedium.copyWith(
          color: TriageColors.textPrimary,
        ),
      ),
      trailing: selected
          ? TriageIcon(
              TriageIcons.check,
              size: TriageSizes.icon,
              color: context.triageRole.accent,
            )
          : null,
    );
  }
}
