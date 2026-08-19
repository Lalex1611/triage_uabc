import 'package:sistema_triage/core/config/supabase_env.dart';

/// Compatibilidad para flujos viejos que inicializan Supabase via AppEnv
class AppEnv {
  AppEnv._();

  static bool _loaded = false;

  static Future<void> load() async {
    _loaded = true;
    _validate();
  }

  static void _validate() {
    if (!SupabaseEnv.isConfigured) {
      throw StateError(
        'Faltan SUPABASE_URL o SUPABASE_ANON_KEY. '
        'Configura assets/supabase_runtime.json o --dart-define.',
      );
    }
  }

  static String get supabaseUrl {
    _ensureLoaded();
    return SupabaseEnv.projectUrl;
  }

  static String get supabaseAnonKey {
    _ensureLoaded();
    return SupabaseEnv.anonKey;
  }

  static void _ensureLoaded() {
    if (!_loaded) {
      throw StateError(
        'AppEnv.load() debe llamarse antes de acceder a las variables.',
      );
    }
  }
}
