/// Lee `SUPABASE_URL` y `SUPABASE_ANON_KEY`:
/// 1) `assets/supabase_runtime.json` tras [loadSupabaseRuntimeAsset] (valores no vacíos tienen prioridad),
/// 2) si faltan en el asset, `--dart-define` / `--dart-define-from-file`
/// Script: `sync_supabase_asset.ps1` para copiar el define al asset
class SupabaseEnv {
  SupabaseEnv._();

  static const String _urlDefine = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _anonDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String? _urlFallback;
  static String? _anonFallback;

  /// Llamado desde [loadSupabaseRuntimeAsset] antes de [Supabase.initialize]
  static void applyRuntimeFallback({String? url, String? anonKey}) {
    final u = url?.trim();
    final a = anonKey?.trim();
    if (u != null && u.isNotEmpty) _urlFallback = u;
    if (a != null && a.isNotEmpty) _anonFallback = a;
  }

  /// Preferencia: asset embebido (tras [loadSupabaseRuntimeAsset]) > `--dart-define`
  ///
  /// Si el define queda con valores incorrectos pero no vacíos (p. ej. URL con `/rest/v1`
  /// duplicado o clave antigua), antes no se usaba el JSON del APK y PostgREST devolvía
  /// errores genéricos como «Database error querying schema»
  static String get url =>
      (_urlFallback != null && _urlFallback!.isNotEmpty)
          ? _urlFallback!
          : _urlDefine;

  static String get anonKey =>
      (_anonFallback != null && _anonFallback!.isNotEmpty)
          ? _anonFallback!
          : _anonDefine;

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Solo `https://ref.supabase.co` — **sin** `/rest/v1`
  /// Si en el define pegas la URL de PostgREST (`.../rest/v1`), el SDK arma
  /// rutas duplicadas y PostgREST devuelve errores genéricos ("querying schema")
  static String get projectUrl {
    var s = url.trim();
    if (s.isEmpty) return s;
    s = s.replaceAll(RegExp(r'/+$'), '');
    while (s.toLowerCase().endsWith('/rest/v1')) {
      s = s.substring(0, s.length - '/rest/v1'.length);
      s = s.replaceAll(RegExp(r'/+$'), '');
    }
    return s;
  }
}
