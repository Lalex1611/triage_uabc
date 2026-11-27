import 'package:flutter/material.dart';
import 'package:sistema_triage/features/paramedico/presentation/offline/offline_connection_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/offline/offline_capture_page.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:sistema_triage/features/auth/presentation/login/login_screen.dart';
import 'package:sistema_triage/features/consulta_externa/domain/consulta_lookup_result.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_input_screen.dart';
import 'package:sistema_triage/features/consulta_externa/presentation/screens/consulta_status_screen.dart';
import 'package:sistema_triage/features/medico/presentation/routing/medico_home_flow_page.dart';
import 'package:sistema_triage/features/medico/presentation/routing/medico_patient_details_flow_page.dart';
import 'package:sistema_triage/features/medico/presentation/register_patient/medico_offline_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/routing/incident_details_flow_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/routing/paramedico_map_tab_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/routing/paramedico_shell_page.dart';
import 'package:sistema_triage/features/paramedico/presentation/routing/patient_details_flow_page.dart';
import 'package:sistema_triage/core/router/router_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/auth',
  refreshListenable: AuthGate.instance,
  redirect: _redirect,
  routes: [
    GoRoute(
      path: '/sin-conexion',
      builder: (context, state) => ListenableBuilder(
        listenable: AuthGate.instance,
        builder: (context, _) => AuthGate.instance.role == AppUserRole.medico
            ? const MedicoOfflinePage()
            : const OfflineConnectionFlowPage(),
      ),
    ),
    GoRoute(
      path: '/paramedico/captura/:id',
      builder: (context, state) =>
          OfflineCapturePage(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/paramedico',
      redirect: (context, state) {
        // No usar `matchedLocation == '/paramedico'`: para rutas hijas el prefijo
        // sigue siendo `/paramedico` y este redirect devolvía siempre a home
        final p = state.uri.path;
        if (p == '/paramedico' || p == '/paramedico/') {
          return '/paramedico/mapa';
        }
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ParamedicoShellPage(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'mapa',
                  builder: (context, state) {
                    final focus = state.uri.queryParameters['focus'];
                    return ParamedicoMapTabPage(
                      initialFocusIncidentId: focus?.isNotEmpty == true
                          ? focus
                          : null,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: 'incident/:incidentId',
          builder: (context, state) {
            final id = state.pathParameters['incidentId']!;
            return IncidentDetailsFlowPage(incidentId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: 'patient/:patientId',
          builder: (context, state) {
            final id = state.pathParameters['patientId']!;
            return PatientDetailsFlowPage(patientId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/medico',
      builder: (context, state) => const MedicoHomeFlowPage(),
    ),
    GoRoute(
      path: '/medico/capturas',
      builder: (context, state) => const MedicoOfflinePage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/medico/paciente/:patientId',
      builder: (context, state) {
        final id = state.pathParameters['patientId']!;
        return MedicoPatientDetailsFlowPage(patientId: id);
      },
    ),
    GoRoute(
      path: '/consulta-externa',
      builder: (context, state) => const ConsultaInputScreen(),
    ),
    GoRoute(
      path: '/consulta-status',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is ConsultaLookupResult) {
          return ConsultaStatusScreen(result: extra);
        }
        return const ConsultaInputScreen();
      },
    ),
  ],
);

String? _redirect(BuildContext context, GoRouterState state) {
  final loc = state.matchedLocation;
  if (loc == '/sin-conexion') return null;
  final configured = SupabaseEnv.isConfigured;

  final publicRoutes =
      loc == '/consulta-externa' || loc == '/consulta-status' || loc == '/auth';

  if (!configured) {
    if (loc == '/auth') return null;
    return '/auth';
  }

  final session = Supabase.instance.client.auth.currentSession;
  final loggedIn = session != null;
  final role = AuthGate.instance.role;

  if (!loggedIn) {
    if (publicRoutes) return null;
    return '/auth';
  }

  if (role == null && loc != '/auth') {
    return '/auth';
  }

  if (loggedIn && role != null) {
    if (loc == '/auth') {
      return role.homePath;
    }
    if (loc.startsWith('/paramedico') && role != AppUserRole.paramedico) {
      return role.homePath;
    }
    if ((loc == '/medico' || loc.startsWith('/medico/')) &&
        role != AppUserRole.medico) {
      return role.homePath;
    }
  }

  return null;
}
