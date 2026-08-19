import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/features/auth/domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps [role] in sync with Supabase auth + `profiles.role` for GoRouter redirects
class AuthGate extends ChangeNotifier {
  AuthGate._();

  static final AuthGate instance = AuthGate._();

  AppUserRole? role;
  String? _hospitalId;
  String? _fullName;
  String? get hospitalId => _hospitalId;
  String? get fullName => _fullName;

  StreamSubscription<dynamic>? _sub;

  /// Set when a session is closed because `profiles.role` is [AppUserRole.consultaExterna]
  /// (consulta por código es anónima; no hay “home” con correo para ese rol)
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

    _sub ??= Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      syncFromSession();
    });

    await syncFromSession();
  }

  Future<void> syncFromSession() async {
    if (!SupabaseEnv.isConfigured) {
      role = null;
      _hospitalId = null;
      _fullName = null;
      notifyListeners();
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      role = null;
      _hospitalId = null;
      _fullName = null;
      notifyListeners();
      return;
    }

    _consultaExternaStaffBlockPending = false;

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role, hospital_id, full_name')
          .eq('id', session.user.id)
          .maybeSingle();

      final parsed = AppUserRole.fromDb(row?['role'] as String?);
      if (parsed == AppUserRole.consultaExterna) {
        _consultaExternaStaffBlockPending = true;
        await Supabase.instance.client.auth.signOut();
        role = null;
        _hospitalId = null;
        _fullName = null;
        notifyListeners();
        return;
      }

      role = parsed;
      final hid = row?['hospital_id'];
      _hospitalId = hid?.toString();
      final fn = row?['full_name'] as String?;
      _fullName = (fn != null && fn.trim().isNotEmpty)
          ? fn.trim()
          : session.user.email;
    } catch (_) {
      role = null;
      _hospitalId = null;
      _fullName = null;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!SupabaseEnv.isConfigured) return;
    _consultaExternaStaffBlockPending = false;
    await Supabase.instance.client.auth.signOut();
    role = null;
    _hospitalId = null;
    _fullName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
