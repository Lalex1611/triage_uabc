import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sincroniza [role] con la sesión de Supabase y `profiles.role` para las
/// redirecciones de GoRouter.
class AuthGate extends ChangeNotifier {
  AuthGate._();

  static final AuthGate instance = AuthGate._();

  AppUserRole? role;
  String? _verifiedAccount;
  int sessionGeneration = 0;
  bool lastVerificationSucceeded = false;
  String? get _verifiedSessionAccount {
    if (!SupabaseEnv.isConfigured) return null;
    final session = Supabase.instance.client.auth.currentSession;
    return session != null &&
            !session.isExpired &&
            session.user.id == _verifiedAccount
        ? _verifiedAccount
        : null;
  }

  String? get offlineAccount =>
      role == AppUserRole.paramedico ? _verifiedSessionAccount : null;

  ({String account, String hospitalId})? get medicoOfflineSession {
    final account = _verifiedSessionAccount;
    final hospital = _hospitalId;
    return role == AppUserRole.medico &&
            account != null &&
            hospital != null &&
            hospital.isNotEmpty
        ? (account: account, hospitalId: hospital)
        : null;
  }

  String? _hospitalId;
  String? _fullName;
  String? get hospitalId => _hospitalId;
  String? get fullName => _fullName;

  StreamSubscription<dynamic>? _sub;

  /// Se activa al cerrar una sesión cuyo `profiles.role` es
  /// [AppUserRole.consultaExterna]. Ese rol accede de forma anónima por código.
  bool _consultaExternaStaffBlockPending = false;

  /// Consume el aviso de que el último inicio de sesión fue rechazado por rol solo-consulta
  bool takeConsultaExternaStaffBlock() {
    if (!_consultaExternaStaffBlockPending) return false;
    _consultaExternaStaffBlockPending = false;
    return true;
  }

  Future<void> initialize() async {
    if (!SupabaseEnv.isConfigured) {
      role = null;
      _hospitalId = null;
      _fullName = null;
      return;
    }

    _sub ??= Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.tokenRefreshed ||
          event.event == AuthChangeEvent.signedOut) {
        sessionGeneration++;
      }
      syncFromSession();
    });

    await syncFromSession();
  }

  Future<void> syncFromSession() async {
    lastVerificationSucceeded = false;
    if (!SupabaseEnv.isConfigured) {
      role = null;
      _hospitalId = null;
      _fullName = null;
      notifyListeners();
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _verifiedAccount = null;
      sessionGeneration++;
      role = null;
      _hospitalId = null;
      _fullName = null;
      notifyListeners();
      return;
    }

    _consultaExternaStaffBlockPending = false;

    final requestGeneration = sessionGeneration;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role, hospital_id, full_name, is_active')
          .eq('id', session.user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (Supabase.instance.client.auth.currentSession?.user.id !=
              session.user.id ||
          sessionGeneration != requestGeneration) {
        return;
      }

      final parsed = row?['is_active'] == true
          ? AppUserRole.fromDb(row?['role'] as String?)
          : null;
      if (parsed == AppUserRole.consultaExterna) {
        _consultaExternaStaffBlockPending = true;
        await Supabase.instance.client.auth.signOut();
        role = null;
        _hospitalId = null;
        _fullName = null;
        notifyListeners();
        return;
      }

      final hospital = row?['hospital_id']?.toString();
      final verified =
          parsed == AppUserRole.paramedico || parsed == AppUserRole.medico
          ? session.user.id
          : null;
      if (_verifiedAccount != verified ||
          role != parsed ||
          _hospitalId != hospital) {
        sessionGeneration++;
      }
      role = parsed;
      _verifiedAccount = verified;
      lastVerificationSucceeded = true;
      _hospitalId = hospital;
      final fn = row?['full_name'] as String?;
      _fullName = (fn != null && fn.trim().isNotEmpty)
          ? fn.trim()
          : session.user.email;
    } catch (_) {
      if (Supabase.instance.client.auth.currentSession?.user.id !=
              session.user.id ||
          sessionGeneration != requestGeneration) {
        return;
      }
      // La autorización sin conexión se mantiene solo en memoria. Una sesión
      // verificada y vigente puede seguir capturando si se pierde la conexión.
      if (offlineAccount == session.user.id ||
          medicoOfflineSession?.account == session.user.id) {
        notifyListeners();
        return;
      }
      _verifiedAccount = null;
      role = null;
      _hospitalId = null;
      _fullName = null;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!SupabaseEnv.isConfigured) return;
    _consultaExternaStaffBlockPending = false;
    _verifiedAccount = null;
    sessionGeneration++;
    role = null;
    _hospitalId = null;
    _fullName = null;
    notifyListeners();
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
