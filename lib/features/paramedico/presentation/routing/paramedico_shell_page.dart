import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/shared/widgets/triage_ui.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/incidents/paramedico_incidents_sheet.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_session_actions.dart';
import 'package:sistema_triage/features/paramedico/presentation/start_guide/paramedico_start_guide.dart';

/// Deja que el mapa oculte la barra de navegación mientras hay un incidente
/// elegido (B03), como en Figma
class ParamedicoNavbarVisibility extends InheritedWidget {
  const ParamedicoNavbarVisibility({
    super.key,
    required this.hidden,
    required super.child,
  });

  final ValueNotifier<bool> hidden;

  static ValueNotifier<bool>? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<ParamedicoNavbarVisibility>()
      ?.hidden;

  @override
  bool updateShouldNotify(ParamedicoNavbarVisibility oldWidget) =>
      hidden != oldWidget.hidden;
}

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

  /// La hoja de Guía rápida START está abierta (B19): su pestaña se marca y el
  /// "+" se oculta
  bool _guideOpen = false;

  final _navbarHidden = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _navbarHidden.addListener(_onNavbarHiddenChanged);
  }

  @override
  void dispose() {
    _navbarHidden.dispose();
    super.dispose();
  }

  // El mapa puede pedirlo mientras se construye (al enfocar desde la ruta):
  // el shell, que está por encima, se reconstruye al terminar ese cuadro
  void _onNavbarHiddenChanged() {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  StatefulNavigationShell get _shell => widget.navigationShell;

  int get _branchIndex =>
      _shell.currentIndex < _navBranchCount ? _shell.currentIndex : -1;

  int get _navIndex {
    if (_incidentsOpen) return ParamedicoNavbar.incidentsTab;
    if (_guideOpen) return ParamedicoNavbar.guideTab;
    return _branchIndex;
  }

  /// Navegador de la rama actual. Lo que se abre en él queda dentro del cuerpo
  /// del Scaffold, así que la barra de navegación se pinta por delante.
  BuildContext get _branchContext =>
      _shell.route.branches[_shell.currentIndex].navigatorKey.currentContext ??
      context;

  /// Cierra la hoja activa (incidentes o guía START) y lo que se haya abierto
  /// encima, sin tocar las pantallas de la rama
  void _closeActiveSheets() =>
      Navigator.of(_branchContext).popUntil((route) => route is! PopupRoute);

  Future<void> _openIncidents() async {
    if (_incidentsOpen) return;
    if (_guideOpen) _closeActiveSheets();
    setState(() => _incidentsOpen = true);
    await showParamedicoIncidentsSheet(context, host: _branchContext);
    if (mounted) setState(() => _incidentsOpen = false);
  }

  Future<void> _openGuide() async {
    if (_guideOpen) return;
    if (_incidentsOpen) _closeActiveSheets();
    setState(() => _guideOpen = true);
    await ParamedicoStartGuide.show(context, host: _branchContext);
    if (mounted) setState(() => _guideOpen = false);
  }

  void _onNavTap(int index) {
    if (index == ParamedicoNavbar.incidentsTab) {
      unawaited(_openIncidents());
      return;
    }
    if (index == ParamedicoNavbar.guideTab) {
      unawaited(_openGuide());
      return;
    }
    if (_incidentsOpen || _guideOpen) _closeActiveSheets();
    if (index == ParamedicoNavbar.profileTab) {
      ParamedicoSessionActions.openProfileSheet(context);
      return;
    }
    if (index == ParamedicoNavbar.mapTab && !_incidentsOpen && !_guideOpen) {
      _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onMapBranch = _branchIndex == ParamedicoNavbar.mapTab;
    final hideNavbar = onMapBranch && _navbarHidden.value;

    return Scaffold(
      backgroundColor: TriageColors.surface,
      resizeToAvoidBottomInset: false,
      // En el mapa la píldora flota sobre él y la pantalla recibe su alto en
      // el padding inferior de MediaQuery. shortcut: las ramas antiguas
      // (incidentes, home, paciente) tienen listas con padding fijo que
      // quedarían tapadas; flotar también ahí cuando se migren.
      extendBody: onMapBranch,
      body: ParamedicoNavbarVisibility(hidden: _navbarHidden, child: _shell),
      bottomNavigationBar: hideNavbar
          ? null
          : ParamedicoNavbar(
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
