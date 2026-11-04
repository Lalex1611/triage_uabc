import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/theme/triage_tokens.dart';
import 'package:sistema_triage/features/paramedico/presentation/navigation/paramedico_navbar_widget.dart';

class ParamedicoShellPage extends StatelessWidget {
  const ParamedicoShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // La barra solo muestra las ramas mapa (0) e incidentes (1). Las ramas
  // home (2) y paciente (3) siguen existiendo en el router pero ya no están
  // en la barra, así que en ellas no se marca ninguna pestaña.
  static const int _navBranchCount = 2;

  int get _navIndex => navigationShell.currentIndex < _navBranchCount
      ? navigationShell.currentIndex
      : -1;

  void _onNavTap(int index) {
    if (index == ParamedicoNavbar.mapTab ||
        index == ParamedicoNavbar.incidentsTab) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }
    // Guía START y Perfil: sin acción por ahora
  }

  // Si tu botón "+" anterior navegaba con otro método (p. ej. el helper de
  // core/router/paramedico_stack_nav.dart), usa ese mismo aquí.
  void _createIncident(BuildContext context) {
    context.push('/paramedico/incident/nuevo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Se ve alrededor de la píldora de navegación
      backgroundColor: TriageColors.surface,
      resizeToAvoidBottomInset: false,
      body: navigationShell,
      bottomNavigationBar: ParamedicoNavbar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        onCreateIncident: () => _createIncident(context),
      ),
    );
  }
}