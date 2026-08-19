import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';

/// Carga `assets/supabase_runtime.json` si existe (mismo formato que [supabase.define.example.json])
///
/// Tras cargar, [SupabaseEnv] prioriza estos valores sobre `--dart-define` cuando no están vacíos,
/// para que el APK embebido no quede atado a defines incorrectos en la compilación
Future<void> loadSupabaseRuntimeAsset() async {
  try {
    final raw = await rootBundle.loadString('assets/supabase_runtime.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    SupabaseEnv.applyRuntimeFallback(
      url: j['SUPABASE_URL'] as String?,
      anonKey: j['SUPABASE_ANON_KEY'] as String?,
    );
  } catch (_) {
    // Sin asset o JSON inválido: no hace nada
  }
}
