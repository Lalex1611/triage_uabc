import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_session_actions.dart';
import 'package:sistema_triage/features/paramedico/presentation/incidents/paramedico_incidents_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_sheet.dart';

class ParamedicoShellPage extends StatefulWidget {
  const ParamedicoShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ParamedicoShellPage> createState() => _ParamedicoShellPageState();
}

class _ParamedicoShellPageState extends State<ParamedicoShellPage> {
  // La barra solo muestra las ramas mapa (0) e incidentes (1). Las ramas
  // home (2) y paciente (3) siguen existiendo en el router pero ya no están
  // en la barra, así que en ellas no se marca ninguna pestaña.
  static const int _navBranchCount = 2;

  /// La hoja de Incidentes activos está abierta: su pestaña se marca y el "+"
  /// se oculta, como en Figma (B02)
  bool _incidentsOpen = false;

  StatefulNavigationShell get _shell => widget.navigationShell;

  int get _branchIndex =>
      _shell.currentIndex < _navBranchCount ? _shell.currentIndex : -1;

  int get _navIndex =>
      _incidentsOpen ? ParamedicoNavbar.incidentsTab : _branchIndex;

  /// Navegador de la rama actual. Lo que se abre en él queda dentro del cuerpo
  /// del Scaffold, así que la barra de navegación se pinta por delante.
  BuildContext get _branchContext =>
      _shell.route.branches[_shell.currentIndex].navigatorKey.currentContext ??
      context;

  /// Cierra la hoja de incidentes y lo que se haya abierto encima (ordenar,
  /// filtrar), sin tocar las pantallas de la rama
  void _closeIncidents() =>
      Navigator.of(_branchContext).popUntil((route) => route is! PopupRoute);

  Future<void> _openIncidents() async {
    if (_incidentsOpen) return;
    setState(() => _incidentsOpen = true);
    await showParamedicoIncidentsSheet(context, host: _branchContext);
    if (mounted) setState(() => _incidentsOpen = false);
  }

  void _onNavTap(int index) {
    if (index == ParamedicoNavbar.incidentsTab) {
      unawaited(_openIncidents());
      return;
    }
    if (_incidentsOpen) _closeIncidents();
    if (index == ParamedicoNavbar.profileTab) {
      ParamedicoSessionActions.openProfileSheet(context);
      return;
    }
    if (index == ParamedicoNavbar.mapTab && !_incidentsOpen) {
      _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onMapBranch = _branchIndex == ParamedicoNavbar.mapTab;

    return Scaffold(
      backgroundColor: TriageColors.surface,
      resizeToAvoidBottomInset: false,
      // En el mapa la píldora flota sobre él y la pantalla recibe su alto en
      // el padding inferior de MediaQuery. shortcut: las ramas antiguas
      // (incidentes, home, paciente) tienen listas con padding fijo que
      // quedarían tapadas; flotar también ahí cuando se migren.
      extendBody: onMapBranch,
      body: _shell,
      bottomNavigationBar: ParamedicoNavbar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        // En Figma el "+" solo está en el mapa
        onCreateIncident: _navIndex == ParamedicoNavbar.mapTab
            ? () => unawaited(showCreateIncidentSheet(context))
            : null,
      ),
    );
  }
}
